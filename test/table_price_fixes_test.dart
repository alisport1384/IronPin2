import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironpin/data/public_tables.dart';
import 'package:ironpin/domain/market.dart';
import 'package:ironpin/domain/searcher.dart';
import 'package:ironpin/ui/prices_page.dart';

void main() {
  final fetched = DateTime.utc(2026, 11, 24, 17, 0);

  test(
      'Shahr-style product row with "قیمت ..." and specs labels never overwrites table headers',
      () {
    const html = '''
      <h2>توری و فنس</h2>
      <p>آخرین بروزرسانی قیمت: 1405/09/03</p>
      <table>
        <thead>
          <tr>
            <th>محصول</th><th>حالت</th><th>ضخامت</th><th>سایز چشمه توری</th>
            <th>واحد فروش</th><th>محل بارگیری</th><th>قیمت (تومان)</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><a href="/p/1">قیمت فنس مربعی 2×2 مفتول 3.6</a><br>محل بارگیری:بنگاه تهران<br>واحد فروش:متر<br>سایز چشمه توری:2x2<br>ضخامت:0.4</td>
            <td>حصاری</td><td>0.4</td><td>2x2</td><td>متر</td><td>بنگاه تهران</td><td>173,800</td>
          </tr>
          <tr>
            <td><a href="/p/2">توری حصاری چشمه 5.5 مفتول 2.4</a><br>محل بارگیری:کارخانه<br>واحد فروش:متر<br>سایز چشمه توری:5.5<br>ضخامت:2.4</td>
            <td>حصاری</td><td>2.4</td><td>5.5</td><td>متر</td><td>کارخانه</td><td>223,250</td>
          </tr>
        </tbody>
      </table>
    ''';

    final rows = PublicTables.read(
      body: html,
      url: 'https://shahrahan.com/categories/601-mesh',
      endpoint: 'ext-1',
      seller: 'شهر آهن',
      city: 'تهران',
      category: 'عمومی',
      fetchedAt: fetched,
      headingOwned: true,
    );

    expect(rows.length, 2);
    final second = rows[1];
    expect(second.title, contains('توری حصاری چشمه 5.5 مفتول 2.4'));
    expect(second.amount, 223250);
    expect(second.unit, 'm');
    expect(second.thickness, '2.4');
    expect(second.loading, 'کارخانه');
  });

  test(
      'noise/specification text inside price cell produces no text-amount and is excluded from prices archive',
      () {
    const html = '''
      <h2>توری حصاری</h2>
      <p>آخرین بروزرسانی قیمت: 1405/09/03</p>
      <table>
        <tr><th>محصول</th><th>واحد</th><th>قیمت (تومان)</th></tr>
        <tr>
          <td>توری حصاری چشمه 5.5 مفتول 2.4</td>
          <td>متر</td>
          <td>توری حصاری چشمه 5.5 مفتول 2.4 محل بارگیری: کارخانه واحد فروش: متر سایز چشمه توری: 5.5 ضخامت: 2.4</td>
        </tr>
      </table>
    ''';

    final rows = PublicTables.read(
      body: html,
      url: 'https://example.com/mesh',
      endpoint: 'ext-2',
      seller: 'شهر آهن',
      city: 'تهران',
      category: 'توری',
      fetchedAt: fetched,
      headingOwned: true,
    );
    expect(rows.length, 1);
    expect(rows.single.amount, isNull);
    expect(rows.single.hasUsableTextAmount, isFalse);

    final result = Searcher.process(rows, now: fetched, windowDays: 3);
    expect(result.quotes, isEmpty);
  });

  test(
      'approximate unit-conversion cell ("3,219,000 هر شاخه ≈ 108,636/کیلوگرم") resolves to the unit-matched single price',
      () {
    const html = '''
      <h2>میلگرد آجدار آریان فولاد</h2>
      <p>آخرین بروزرسانی قیمت: 1405/09/03</p>
      <table>
        <tr><th>محصول</th><th>سایز</th><th>واحد</th><th>قیمت (تومان)</th></tr>
        <tr>
          <td>میلگرد آجدار 20 آریان فولاد</td>
          <td>20</td>
          <td>کیلوگرم</td>
          <td>3,219,000 هر شاخه ≈ 108,636/کیلوگرم</td>
        </tr>
      </table>
    ''';

    final rows = PublicTables.read(
      body: html,
      url: 'https://example.com/rebar',
      endpoint: 'ext-3',
      seller: 'فروشنده نمونه',
      city: 'تهران',
      category: 'میلگرد',
      fetchedAt: fetched,
      headingOwned: true,
    );

    expect(rows.length, 1);
    final q = rows.single;
    expect(q.amount, 108636);
    expect(q.unit, 'kg');
    expect(q.currency, 'تومان');
    expect(q.details['معادل تبدیل منبع'], contains('≈'));
  });

  test(
      'adjacent Persian/Latin prices and fluctuation span do not merge into trillion numbers or 3-number strings',
      () {
    const html = '''
      <h2>قیمت تیرآهن و توری</h2>
      <p>آخرین بروزرسانی قیمت: 1405/09/03</p>
      <table>
        <tr><th>محصول</th><th>واحد</th><th>قیمت (تومان)</th></tr>
        <tr>
          <td>تیرآهن 20 IPE فابریک فایکو</td>
          <td>شاخه</td>
          <td>36,300,000 33,000,000 <span class="change down">880,000</span></td>
        </tr>
        <tr>
          <td>توری پرسی 2×2</td>
          <td>متر</td>
          <td>1,579,500۱٬۷۳۷٬۰۰۰</td>
        </tr>
      </table>
    ''';

    final rows = PublicTables.read(
      body: html,
      url: 'https://example.com/beam',
      endpoint: 'ext-4',
      seller: 'فروشنده نمونه',
      city: 'تهران',
      category: 'عمومی',
      fetchedAt: fetched,
      headingOwned: true,
    );

    expect(rows.length, 2);
    expect(rows[0].details['مبلغ چندگانه'], 'بله');
    expect(rows[0].details['تفکیک منبع'], 'با و بدون ارزش افزوده');
    expect(rows[0].details['مبلغ استخراج‌شده'], '36,300,000 33,000,000');

    expect(rows[1].details['مبلغ چندگانه'], 'بله');
    expect(rows[1].details['تفکیک منبع'], 'با و بدون ارزش افزوده');
    expect(rows[1].details['مبلغ استخراج‌شده'], '1,579,500 1,737,000');
  });

  testWidgets(
      'QuoteCard hides raw multi-price/spec strings in main price slot',
      (t) async {
    final multiTaxQuote = Quote(
      id: 'q1',
      endpoint: 'e1',
      seller: 'فروشنده',
      sellerCity: 'تهران',
      title: 'تیرآهن 20 فایکو',
      category: 'تیرآهن',
      amount: null,
      currency: 'تومان',
      unit: 'piece',
      fetchedAt: fetched,
      sourceUrl: 'https://example.com',
      sourceDateRaw: fetched.toIso8601String(),
      details: const {
        'مبلغ استخراج‌شده': '36,300,000 33,000,000',
        'مبلغ چندگانه': 'بله',
        'تفکیک منبع': 'با و بدون ارزش افزوده',
      },
    );
    final legacySpecNoiseQuote = Quote(
      id: 'q2',
      endpoint: 'e2',
      seller: 'شهر آهن',
      sellerCity: 'تهران',
      title: 'توری حصاری چشمه 5.5 مفتول 2.4',
      category: 'توری',
      amount: null,
      currency: 'نامشخص',
      unit: 'unknown',
      fetchedAt: fetched,
      sourceUrl: 'https://example.com',
      sourceDateRaw: fetched.toIso8601String(),
      details: const {
        'مبلغ استخراج‌شده':
            'توری حصاری چشمه 5.5 مفتول 2.4 محل بارگیری: کارخانه واحد فروش: متر سایز چشمه توری: 5.5 ضخامت: 2.4',
      },
    );

    await t.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: ListView(
            children: [
              QuoteCard(q: multiTaxQuote, basis: 'original', onChart: () {}),
              QuoteCard(
                  q: legacySpecNoiseQuote, basis: 'original', onChart: () {}),
            ],
          ),
        ),
      ),
    ));

    expect(find.text('چند مبلغی (با/بی‌مالیات)'), findsOneWidget);
    expect(find.textContaining('36,300,000'), findsNothing);
    expect(find.text('نامشخص'), findsOneWidget);
    expect(find.text('بدون قیمت معتبر'), findsOneWidget);
  });
}
