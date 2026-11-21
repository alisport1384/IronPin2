import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ironpin/data/external_scanner.dart';

void main() {
  test('external scanner requests only the incremental server feed and drops unpriced rows', () async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(jsonEncode({
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
      }), 200, headers: {'content-type': 'application/json'});
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
}
