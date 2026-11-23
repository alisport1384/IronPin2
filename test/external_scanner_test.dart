import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ironpin/data/controller.dart';
import 'package:ironpin/data/external_scanner.dart';
import 'package:ironpin/data/sources.dart';
import 'package:ironpin/data/store.dart';
import 'package:ironpin/domain/source_finder.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  test(
      'external scanner fetches Searcher-2 sources, skips unreadable kinds, and normalizes legacy URLs',
      () async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response.bytes(
          utf8.encode(jsonEncode({
            'format': 'ironpin-sources-v1',
            'epoch': 2,
            'round': 5,
            'sources': [
              {
                'key': 'site:seller.example/prices',
                'url': 'https://seller.example/prices',
                'kind': 'site',
                'part': 0,
                'readable': true,
                'name': 'فولاد نمونه',
                'city': 'تهران',
              },
              {
                'key': 'telegram:steel_ch',
                'url': 'https://t.me/steel_ch',
                'kind': 'telegram',
                'part': 1,
                'readable': true,
                'name': 'کانال فولاد',
                'city': 'مشهد',
              },
              {
                'key': 'instagram:steel_ig',
                'url': 'https://www.instagram.com/steel_ig/',
                'kind': 'instagram',
                'part': 1,
                'readable': false,
                'name': 'اینستاگرام',
                'city': 'تهران',
              },
            ],
          })),
          200,
          headers: {'content-type': 'application/json'});
    });

    final batch = await ExternalScanner.fetchSources(
      client,
      url: 'https://qwen.alisport0.qzz.io/api/ironpin',
    );
    expect(requested?.path, '/api/sources');
    expect(batch.epoch, 2);
    expect(batch.round, 5);
    expect(batch.totalFromServer, 3);
    expect(batch.sources.map((e) => e.url).toList(), [
      'https://seller.example/prices',
      'https://t.me/s/steel_ch',
    ]);
    expect(batch.sources.first.parser, 'site-table');
    expect(batch.sources.last.parser, 'telegram');
    client.close();
  });

  test(
      'external mode refresh fetches server sources and runs Searcher-1 ONLY on those sources',
      () async {
    final store = await MarketStore.open(
        dbPath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      if (request.url.path == '/api/sources') {
        return http.Response.bytes(
            utf8.encode(jsonEncode({
              'format': 'ironpin-sources-v1',
              'epoch': 1,
              'round': 1,
              'sources': [
                {
                  'key': 'site:seller.example/prices',
                  'url': 'https://seller.example/prices',
                  'kind': 'site',
                  'part': 0,
                  'readable': true,
                  'name': 'فولاد نمونه',
                  'city': 'تهران',
                },
              ],
            })),
            200,
            headers: {'content-type': 'application/json'});
      }
      if (request.url.toString() == 'https://seller.example/prices') {
        return http.Response.bytes(
            utf8.encode('''
              <!doctype html>
              <html>
              <head><title>لیست قیمت میلگرد | فولاد نمونه</title></head>
              <body>
                <h2>قیمت میلگرد 16</h2>
                <table>
                  <thead>
                    <tr>
                      <th>محصول</th>
                      <th>کارخانه</th>
                      <th>سایز</th>
                      <th>واحد</th>
                      <th>قیمت (تومان)</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>میلگرد آجدار</td>
                      <td>اصفهان</td>
                      <td>16</td>
                      <td>کیلوگرم</td>
                      <td>28500</td>
                    </tr>
                  </tbody>
                </table>
              </body>
              </html>
            '''),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'});
      }
      return http.Response('unexpected request', 404);
    });

    final c = MarketController(store, client: SourceClient(client: client));
    c.externalScanMode = true;
    try {
      await c.refresh();
      expect(requested.map((u) => u.toString()).toList(), [
        defaultExternalScannerUrl,
        'https://seller.example/prices',
      ]);
      expect(c.externalTotalSources, 1);
      expect(c.finder.running, isFalse);
      final expectedId = 'finder-site-${finderHash('https://seller.example/prices')}';
      final saved = await store.latestFor(expectedId);
      expect(saved, isNotEmpty);
      expect(saved.first.amount, 28500);
      expect(saved.first.category, 'میلگرد');
    } finally {
      c.dispose();
      await store.close();
    }
  });

  test(
      'planRefreshQueue puts unseen candidates first, skips fresh sources when skipFresh=true, and orders stale oldest-first',
      () {
    final now = DateTime.utc(2026, 11, 23, 12, 0);
    final eps = [
      const SourceEndpoint('fresh', 'تازه', 'https://a.example', 'عمومی', 'site-table', 'تهران'),
      const SourceEndpoint('stale_new', 'قدیمی‌تر', 'https://b.example', 'عمومی', 'site-table', 'تهران'),
      const SourceEndpoint('stale_old', 'خیلی قدیمی', 'https://c.example', 'عمومی', 'site-table', 'تهران'),
      const SourceEndpoint('failed', 'خطادار', 'https://d.example', 'عمومی', 'site-table', 'تهران'),
      const SourceEndpoint('unseen', 'کاندید جدید', 'https://e.example', 'عمومی', 'site-table', 'تهران'),
    ];
    final sync = <String, Map<String, Object?>>{
      'fresh': {
        'success_at': now.subtract(const Duration(minutes: 10)).toIso8601String(),
        'attempted_at': now.subtract(const Duration(minutes: 10)).toIso8601String(),
      },
      'stale_new': {
        'success_at': now.subtract(const Duration(minutes: 45)).toIso8601String(),
        'attempted_at': now.subtract(const Duration(minutes: 45)).toIso8601String(),
      },
      'stale_old': {
        'success_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
        'attempted_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
      },
      'failed': {
        'success_at': null,
        'attempted_at': now.subtract(const Duration(minutes: 5)).toIso8601String(),
      },
    };

    final smart = MarketController.planRefreshQueue(eps, sync,
        skipFresh: true, now: now);
    expect(smart.skippedFresh, 1);
    expect(smart.queue.map((e) => e.id).toList(),
        ['unseen', 'failed', 'stale_old', 'stale_new']);

    final forced = MarketController.planRefreshQueue(eps, sync,
        skipFresh: false, now: now);
    expect(forced.skippedFresh, 0);
    expect(forced.queue.map((e) => e.id).toList(),
        ['unseen', 'failed', 'stale_old', 'stale_new', 'fresh']);
  });

  test(
      'external refresh (x > 1) skips recently updated sources and prioritizes new ones unless forceAll=true',
      () async {
    final store = await MarketStore.open(
        dbPath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    var round = 1;
    final hits = <String, int>{};
    const html1 = '''
      <html><body><h2>قیمت میلگرد 16</h2>
      <table><thead><tr><th>محصول</th><th>سایز</th><th>واحد</th><th>قیمت (تومان)</th></tr></thead>
      <tbody><tr><td>میلگرد آجدار</td><td>16</td><td>کیلوگرم</td><td>28500</td></tr></tbody></table>
      </body></html>''';
    const html2 = '''
      <html><body><h2>قیمت تیرآهن 14</h2>
      <table><thead><tr><th>محصول</th><th>سایز</th><th>واحد</th><th>قیمت (تومان)</th></tr></thead>
      <tbody><tr><td>تیرآهن</td><td>14</td><td>کیلوگرم</td><td>31200</td></tr></tbody></table>
      </body></html>''';

    final client = MockClient((request) async {
      final url = request.url.toString();
      hits[url] = (hits[url] ?? 0) + 1;
      if (request.url.path == '/api/sources') {
        final list = [
          {
            'key': 'site:s1.example/p',
            'url': 'https://s1.example/p',
            'kind': 'site',
            'part': 0,
            'readable': true,
            'name': 'فروشنده اول',
            'city': 'تهران',
          },
          if (round >= 2)
            {
              'key': 'site:s2.example/p',
              'url': 'https://s2.example/p',
              'kind': 'site',
              'part': 0,
              'readable': true,
              'name': 'کاندید جدید',
              'city': 'مشهد',
            },
        ];
        return http.Response.bytes(
            utf8.encode(jsonEncode({
              'format': 'ironpin-sources-v1',
              'epoch': 1,
              'round': round,
              'sources': list,
            })),
            200,
            headers: {'content-type': 'application/json'});
      }
      if (url == 'https://s1.example/p') {
        return http.Response.bytes(utf8.encode(html1), 200,
            headers: {'content-type': 'text/html; charset=utf-8'});
      }
      if (url == 'https://s2.example/p') {
        return http.Response.bytes(utf8.encode(html2), 200,
            headers: {'content-type': 'text/html; charset=utf-8'});
      }
      return http.Response('not found', 404);
    });

    final c = MarketController(store, client: SourceClient(client: client));
    c.externalScanMode = true;
    try {
      // Round 1: only s1 exists -> fetched once
      await c.refresh();
      expect(hits['https://s1.example/p'], 1);
      expect(hits['https://s2.example/p'], isNull);

      // Round 2 (x > 1): s1 is fresh (< 30 min) so skipped; new s2 is fetched
      round = 2;
      await c.refresh();
      expect(hits['https://s1.example/p'], 1);
      expect(hits['https://s2.example/p'], 1);
      expect(c.refreshSkipped, 1);
      expect(c.refreshTotal, 1);

      // Round 3: both fresh -> skipped quickly unless forceAll=true
      await c.refresh();
      expect(hits['https://s1.example/p'], 1);
      expect(hits['https://s2.example/p'], 1);
      expect(c.refreshSkipped, 2);
      expect(c.refreshBlockedReason, contains('نگه دارید'));

      // Round 4 with forceAll=true -> overwrites both
      await c.refresh(forceAll: true);
      expect(hits['https://s1.example/p'], 2);
      expect(hits['https://s2.example/p'], 2);
      expect(c.refreshSkipped, 0);
    } finally {
      c.dispose();
      await store.close();
    }
  });
}
