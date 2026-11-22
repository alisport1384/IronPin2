import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ironpin/data/controller.dart';
import 'package:ironpin/data/external_scanner.dart';
import 'package:ironpin/data/sources.dart';
import 'package:ironpin/data/store.dart';
import 'package:ironpin/domain/market.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });
  test(
      'external scanner requests only the incremental server feed and drops unpriced rows',
      () async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response.bytes(
          utf8.encode(jsonEncode({
            'format': 'ironpin-quotes-v1',
            'cursor': 200,
            'complete': true,
            'quotes': [
              {
                'id': 'priced-1',
                'endpoint': 'qwen-scanner',
                'seller': 'seller.example',
                'sellerCity': 'تهران',
                'title': 'میلگرد 16 قیمت 25000 تومان هر کیلو',
                'category': 'میلگرد',
                'unit': 'kg',
                'currency': 'تومان',
                'amount': 25000,
                'sourceUrl': 'https://seller.example/prices',
                'fetchedAt': '2026-11-21T10:00:00Z',
                'details': {'سایز': '16'}
              },
              {
                'id': 'unpriced-1',
                'endpoint': 'qwen-scanner',
                'seller': 'seller.example',
                'sellerCity': 'تهران',
                'title': 'میلگرد بدون قیمت',
                'category': 'میلگرد',
                'unit': 'unknown',
                'currency': 'نامشخص',
                'amount': null,
                'sourceUrl': 'https://seller.example/prices',
                'fetchedAt': '2026-11-21T10:00:00Z',
                'details': {}
              }
            ]
          })),
          200,
          headers: {'content-type': 'application/json'});
    });
    final batch = await ExternalScanner.fetch(client,
        url: defaultExternalScannerUrl, since: 123);
    expect(requested?.path, '/api/ironpin');
    expect(requested?.queryParameters['since'], '123');
    expect(batch.cursor, 200);
    expect(batch.complete, isTrue);
    expect(batch.quotes.map((q) => q.id), ['priced-1']);
    expect(batch.quotes.single.endpoint, 'qwen-scanner');
    client.close();
  });

  test(
      'first refresh after a feed prune fetches the full snapshot and retires local junk',
      () async {
    final store = await MarketStore.open(
        dbPath: inMemoryDatabasePath, factory: databaseFactoryFfi);
    // An established archive: a junk row from the old feed + a saved cursor.
    await store.saveSnapshot('qwen-scanner', [
      Quote.fromJson({
        'id': 'old-junk',
        'endpoint': 'qwen-scanner',
        'seller': 'seller.example',
        'sellerCity': 'تهران',
        'title': 'درب و پنجره آهنی تبریز',
        'category': 'عمومی',
        'unit': 'unknown',
        'currency': 'تومان',
        'amount': 500000,
        'sourceUrl': 'https://seller.example/old',
        'fetchedAt': '2026-11-01T10:00:00Z',
        'details': <String, String>{},
      }),
    ]);
    await store.setSetting('external.cursor', '111');
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      return http.Response.bytes(
          utf8.encode(jsonEncode({
            'format': 'ironpin-quotes-v1',
            'cursor': 222,
            'complete': true,
            'quotes': [
              {
                'id': 'fresh-1',
                'endpoint': 'qwen-scanner',
                'seller': 'seller.example',
                'sellerCity': 'تهران',
                'title': 'میلگرد 16 قیمت 25000 تومان هر کیلو',
                'category': 'میلگرد',
                'unit': 'kg',
                'currency': 'تومان',
                'amount': 25000,
                'sourceUrl': 'https://seller.example/prices',
                'fetchedAt': '2026-11-22T10:00:00Z',
                'details': <String, String>{},
              },
            ],
          })),
          200,
          headers: {'content-type': 'application/json'});
    });
    final c = MarketController(store, client: SourceClient(client: client));
    c.externalScanMode = true;
    try {
      await c.refresh();
      expect(requested, hasLength(1));
      expect(requested.single.queryParameters.containsKey('since'), isFalse,
          reason: 'feed epoch mismatch must force one full snapshot fetch');
      expect(
          await store.setting('external.resyncEpoch'), externalFeedResyncEpoch);
      expect(await store.setting('external.cursor'), '222');
      final active = await store.latestFor('qwen-scanner');
      expect(active.map((q) => q.id), ['fresh-1'],
          reason: 'local junk must be retired by the full snapshot');
      // The next refresh is incremental again.
      await c.refresh();
      expect(requested.last.queryParameters['since'], '222');
    } finally {
      c.dispose();
      await store.close();
    }
  });
}
