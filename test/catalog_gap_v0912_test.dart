import 'package:flutter_test/flutter_test.dart';
import 'package:ironpin/domain/market.dart';
import 'package:ironpin/domain/product_schema.dart';
import 'package:ironpin/domain/product_text.dart';
import 'package:ironpin/domain/searcher.dart';

/// Catalog-gap audit (2026-11-21): products priced by the online scanner but
/// missing from IronPin, plus field backfills where the scanner carried
/// specs the app schema lacked.
void main() {
  final now = DateTime.utc(2026, 11, 21, 12);

  Quote row(String id, double? amount,
          {String title = 'تیرچه فلزی', String category = 'تیرچه'}) =>
      Quote(
          id: id,
          endpoint: 'test',
          seller: 'فروشنده$id',
          sellerCity: 'تهران',
          title: title,
          category: category,
          amount: amount,
          unit: 'piece',
          currency: 'تومان',
          sourceDateRaw: '2026-11-21T08:00:00Z',
          fetchedAt: now,
          sourceUrl: 'https://example.com',
          details: const {});

  test('تیرچه is a first-class family (live scanner product)', () {
    expect(productFields.containsKey('تیرچه'), true);
    expect(
        productFields['تیرچه']!.keys,
        containsAll(['kind', 'size', 'length', 'material', 'grade', 'mesh']));
    // No source/brand/geography keys in any family schema.
    expect(
        productFields.values
            .every((m) => !m.containsKey('brand') && !m.containsKey('city')),
        true);
  });

  test('تیرچه classifies without stealing تیرآهن', () {
    expect(ProductText.category('قیمت تیرچه فلزی 4 متری'), 'تیرچه');
    expect(ProductText.category('تیرچه بتنی با شبکه فولادی'), 'تیرچه');
    expect(ProductText.category('تیرآهن IPE 180'), 'تیرآهن');
    expect(ProductText.category('میلگرد آجدار 14'), 'میلگرد');
  });

  test('ProductFacts extracts تیرچه kind from details', () {
    final q = row('a', 2500000,
        title: 'تیرچه فلزی 4 متری',
        category: 'تیرچه')
      ..details['نوع'] = 'فلزی'
      ..details['ارتفاع'] = '40';
    final facts = ProductFacts.of(q);
    expect(facts.family, 'تیرچه');
    expect(facts.values['kind'], 'فلزی');
  });

  test('requiredFeatures covers every family the schema declares', () {
    expect(Searcher.requiredFeatures('تیرچه'), ['نوع', 'طول']);
    // Backfilled families must no longer fall through to the empty default.
    for (final family in [
      'سپری',
      'تسمه',
      'چهارپهلو',
      'میلگرد بستر',
      'مش جوشی',
      'رابیتس',
      'شمش',
      'قراضه',
    ]) {
      expect(Searcher.requiredFeatures(family), isNotEmpty,
          reason: '$family lost its required features');
    }
  });

  test('scanner field backfills are labelled in the app schema', () {
    expect(productFields['بولت']!.keys,
        containsAll(['lengthDeployed', 'massNote', 'torque']));
    expect(productFields['تسمه']!.keys, containsAll(['cutPrice', 'tolerance']));
    expect(productFields['توری']!.keys, contains('coating'));
    expect(productFields['رابیتس']!.keys, contains('massNote'));
    expect(productFields['شمش']!.keys, contains('exchange'));
    expect(productFields['قراضه']!.keys,
        containsAll(['contaminant', 'deduction', 'purity']));
    expect(productFields['مش جوشی']!.keys,
        containsAll(['massFormula', 'overlap']));
    expect(productFields['مفتول']!.keys, containsAll(['coil', 'use']));
    expect(productFields['چهارپهلو']!.keys,
        containsAll(['form', 'areaFormula', 'hexKey']));
  });

  test('every declared family has a one-line definition', () {
    for (final family in productFields.keys) {
      expect(productDefinitions[family], isNotNull,
          reason: '$family has no definition');
      expect(productDefinitions[family]!.length, greaterThan(30));
    }
    expect(productDefinitions['تیرچه']!, contains('شبکه'));
  });
}
