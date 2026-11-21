import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/market.dart';

const defaultExternalScannerUrl = 'https://qwen.alisport0.qzz.io/api/ironpin';
const maxExternalScannerBytes = 32 * 1024 * 1024;

class ExternalQuoteBatch {
  final List<Quote> quotes;
  final int cursor;
  final bool complete;
  const ExternalQuoteBatch(this.quotes, this.cursor, this.complete);
}

/// Downloads only the IronPin Quote export. No internal source adapter is
/// called by this service; malformed or unpriced rows are discarded.
class ExternalScanner {
  static Future<ExternalQuoteBatch> fetch(
    http.Client client, {
    String url = defaultExternalScannerUrl,
    int? since,
  }) async {
    final base = Uri.parse(url.trim());
    if (!const {'http', 'https'}.contains(base.scheme) || !base.hasAuthority) {
      throw const FormatException('نشانی اسکنر خارجی معتبر نیست.');
    }
    final endpoint = base.path.endsWith('/api/ironpin')
        ? base
        : base.replace(path: '/api/ironpin');
    final params = Map<String, String>.from(endpoint.queryParameters);
    if (since != null && since > 0) {
      params['since'] = '$since';
    } else {
      params.remove('since');
    }
    final request = http.Request('GET', endpoint.replace(queryParameters: params))
      ..headers['Accept'] = 'application/json';
    final response = await client.send(request).timeout(const Duration(seconds: 75));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException('دریافت اسکنر خارجی ناموفق بود (HTTP ${response.statusCode}).');
    }
    final declared = response.contentLength;
    if (declared != null && declared > maxExternalScannerBytes) {
      throw const FormatException('خروجی اسکنر از سقف ایمن دریافت بزرگ‌تر است.');
    }
    final bytes = BytesBuilder(copy: false);
    var total = 0;
    await for (final part in response.stream.timeout(const Duration(seconds: 75))) {
      total += part.length;
      if (total > maxExternalScannerBytes) {
        throw const FormatException('خروجی اسکنر از سقف ایمن دریافت بزرگ‌تر است.');
      }
      bytes.add(part);
    }
    final decoded = jsonDecode(utf8.decode(bytes.takeBytes()));
    if (decoded is! Map) {
      throw const FormatException('ساختار خروجی اسکنر قابل‌خواندن نیست.');
    }
    final root = Map<String, dynamic>.from(decoded);
    if (root['format'] != 'ironpin-quotes-v1') {
      throw const FormatException('نسخه خروجی با IronPin سازگار نیست.');
    }
    final raw = root['quotes'];
    if (raw is! List) {
      throw const FormatException('فهرست قیمت در پاسخ اسکنر وجود ندارد.');
    }
    final quotes = <Quote>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        final row = Map<String, dynamic>.from(item);
        final amount = (row['amount'] as num?)?.toDouble();
        if (amount == null || !amount.isFinite || amount <= 0) continue;
        row['endpoint'] = 'qwen-scanner';
        final quote = Quote.fromJson(row);
        if (quote.currency != 'تومان' || quote.id.isEmpty) continue;
        quotes.add(quote);
      } catch (_) {
        // One malformed record must not discard the remaining verified rows.
      }
    }
    final cursorValue = root['cursor'];
    final cursor = cursorValue is num
        ? cursorValue.toInt()
        : int.tryParse('$cursorValue') ?? since ?? 0;
    return ExternalQuoteBatch(quotes, cursor, root['complete'] == true);
  }
}
