import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/source_finder.dart';
import 'sources.dart';

const defaultExternalScannerUrl = 'https://qwen.alisport0.qzz.io/api/sources';
const maxExternalScannerBytes = 16 * 1024 * 1024;

class ExternalSourceBatch {
  final List<SourceEndpoint> sources;
  final int totalFromServer;
  final int round;
  final int epoch;
  const ExternalSourceBatch(
    this.sources, {
    this.totalFromServer = 0,
    this.round = 0,
    this.epoch = 1,
  });
}

/// Downloads ONLY the Searcher-2 discovered sources list (`ironpin-sources-v1`)
/// from the server. On-device Searcher-1 + OCR then read ONLY these sources
/// when external mode is active.
class ExternalScanner {
  static Uri normalizeEndpoint(String url) {
    final base = Uri.parse(url.trim());
    if (!const {'http', 'https'}.contains(base.scheme) || !base.hasAuthority) {
      throw const FormatException('نشانی سرور منابع معتبر نیست.');
    }
    if (base.path.endsWith('/api/sources')) return base;
    if (base.path.isEmpty ||
        base.path == '/' ||
        base.path.endsWith('/api/ironpin')) {
      return base.replace(path: '/api/sources');
    }
    return base.replace(path: '/api/sources');
  }

  static Future<ExternalSourceBatch> fetchSources(
    http.Client client, {
    String url = defaultExternalScannerUrl,
  }) async {
    final endpoint = normalizeEndpoint(url);
    final request = http.Request('GET', endpoint)
      ..headers['Accept'] = 'application/json';
    final response =
        await client.send(request).timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
          'دریافت فهرست منابع از سرور ناموفق بود (HTTP ${response.statusCode}).');
    }
    final declared = response.contentLength;
    if (declared != null && declared > maxExternalScannerBytes) {
      throw const FormatException(
          'خروجی سرور منابع از سقف ایمن دریافت بزرگ‌تر است.');
    }
    final bytes = BytesBuilder(copy: false);
    var total = 0;
    await for (final part
        in response.stream.timeout(const Duration(seconds: 45))) {
      total += part.length;
      if (total > maxExternalScannerBytes) {
        throw const FormatException(
            'خروجی سرور منابع از سقف ایمن دریافت بزرگ‌تر است.');
      }
      bytes.add(part);
    }
    final decoded = jsonDecode(utf8.decode(bytes.takeBytes()));
    if (decoded is! Map) {
      throw const FormatException('ساختار فهرست منابع سرور قابل‌خواندن نیست.');
    }
    final root = Map<String, dynamic>.from(decoded);
    if (root['format'] != 'ironpin-sources-v1') {
      throw const FormatException('نسخه خروجی منابع با IronPin سازگار نیست.');
    }
    final raw = root['sources'];
    if (raw is! List) {
      throw const FormatException('فهرست منابع در پاسخ سرور وجود ندارد.');
    }

    final out = <SourceEndpoint>[];
    final seenKeys = <String>{};
    final seenIds = <String>{};
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        final row = Map<String, dynamic>.from(item);
        if (row['readable'] == false) continue;
        final rawUrl = (row['url'] as String? ?? '').trim();
        if (rawUrl.isEmpty) continue;
        final kind = (row['kind'] as String? ?? '').trim();
        final rawCity = (row['city'] as String? ?? '').trim();
        final city = rawCity.isEmpty ? 'نامشخص' : rawCity;
        final name = (row['name'] as String? ?? '').trim();

        SourceEndpoint? ep;
        if (kind == 'site') {
          final uri = Uri.tryParse(rawUrl);
          if (uri == null ||
              !const {'http', 'https'}.contains(uri.scheme) ||
              uri.host.isEmpty) {
            continue;
          }
          ep = SourceEndpoint(
            'finder-site-${finderHash(rawUrl)}',
            name.isEmpty ? uri.host : name,
            rawUrl,
            'عمومی',
            'site-table',
            city,
          );
        } else {
          ep = publicChannel(
            rawUrl,
            name: name.isEmpty ? null : name,
            city: city,
          );
        }
        if (ep == null) continue;
        final cKey = endpointCanonicalKey(ep);
        if (seenIds.add(ep.id) && seenKeys.add(cKey)) {
          out.add(ep);
        }
      } catch (_) {
        // Skip malformed entry without dropping valid sources.
      }
    }

    final round = (root['round'] as num?)?.toInt() ?? 0;
    final epoch = (root['epoch'] as num?)?.toInt() ?? 1;
    return ExternalSourceBatch(
      out,
      totalFromServer: raw.length,
      round: round,
      epoch: epoch,
    );
  }
}
