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
}
