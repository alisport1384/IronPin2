import 'package:flutter_test/flutter_test.dart';
import 'package:ironpin/data/public_tables.dart';
import 'package:ironpin/domain/searcher.dart';

void main() {
  test(
      'PublicTables reads site-table rows with inline price unit and inline update date (mashhad-ahan.ir structure)',
      () {
    const html = '''
<html><body>
  <h2>قیمت روز آهن‌آلات</h2>
  <table>
    <thead>
      <tr><th>محصول</th><th>قیمت</th><th></th></tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>ناودانی ۸</strong> شکفته، وزن ۲۸ کیلوگرم</td>
        <td><span class="price">۱۲۸٬۰۰۰</span><span class="unit">تومان / کیلوگرم</span><br><time>آخرین به‌روزرسانی: ۲ آذر ۱۴۰۵</time></td>
        <td><a href="#quote">پیش‌فاکتور</a> نمودار</td>
      </tr>
      <tr>
        <td><strong>ناودانی ۱۰</strong> شکفته، وزن ۴۰ کیلوگرم</td>
        <td><span>۱۲۲٬۰۰۰</span><span>تومان / کیلوگرم</span><span>آخرین به‌روزرسانی: ۲۲ مهر ۱۴۰۵</span></td>
        <td>نمودار</td>
      </tr>
      <tr>
        <td><strong>تیرآهن ۱۴</strong> اصفهان</td>
        <td><span>۲۱٬۰۰۰٬۰۰۰</span><span>تومان / شاخه</span><span>آخرین به‌روزرسانی: ۲ آذر ۱۴۰۵</span></td>
        <td>نمودار</td>
      </tr>
      <tr>
        <td><strong>میلگرد ۱۲</strong> نیشابور</td>
        <td><a href="tel:+985136905551">تماس بگیرید</a></td>
        <td>پیش‌فاکتور</td>
      </tr>
      <tr>
        <td><strong>پروفیل ۵۰۷</strong> هر متر ۲٫۴۴ کیلوگرم</td>
        <td>۱۷۶٬۰۰۰تومانآخرین به‌روزرسانی: ۲۲ مهر ۱۴۰۵</td>
        <td>نمودار</td>
      </tr>
    </tbody>
  </table>
</body></html>
''';

    final fetchedAt = DateTime.utc(2026, 11, 23, 12);
    final rows = PublicTables.read(
      body: html,
      url: 'https://www.mashhad-ahan.ir/',
      endpoint: 'finder-site-mashhad-ahan',
      seller: 'مشهد آهن',
      city: 'مشهد',
      category: 'عمومی',
      fetchedAt: fetchedAt,
      headingOwned: true,
    );

    expect(rows.length, 5);

    // Row 0: ناودانی ۸ شکفته، وزن ۲۸ کیلوگرم -> 128,000 toman/kg, pieceKg=28, date 1405-09-02
    final navdani8 = rows[0];
    expect(navdani8.category, 'ناودانی');
    expect(navdani8.amount, 128000.0);
    expect(navdani8.currency, 'تومان');
    expect(navdani8.unit, 'kg');
    expect(navdani8.pieceKg, 28.0);
    expect(navdani8.priceFor('piece'), closeTo(128000.0 * 28.0, 1e-6));
    expect(navdani8.marketAt, isNotNull);
    expect(navdani8.details['مبنای واحد'], 'عبارت صریح هر واحد در سلول قیمت');
    expect(navdani8.details['مبنای تاریخ'], 'تاریخ نوشته‌شده در سلول قیمت');

    // Row 2: تیرآهن ۱۴ اصفهان -> 21,000,000 toman/piece
    final beam14 = rows[2];
    expect(beam14.category, 'تیرآهن');
    expect(beam14.amount, 21000000.0);
    expect(beam14.currency, 'تومان');
    expect(beam14.unit, 'piece');
    expect(beam14.marketAt, isNotNull);

    // Row 3: تماس بگیرید -> null amount
    final callRow = rows[3];
    expect(callRow.amount, isNull);

    // Row 4: پروفیل ۵۰۷ هر متر ۲٫۴۴ کیلوگرم -> amount 176000, unit unknown (not guessed), pieceKg null
    final profileRow = rows[4];
    expect(profileRow.amount, 176000.0);
    expect(profileRow.currency, 'تومان');
    expect(profileRow.unit, 'unknown');
    expect(profileRow.pieceKg, isNull);
    expect(profileRow.marketAt, isNotNull);

    // Searcher accepts valid dated rows within 30-day window (2 Azar 1405 = 2026-11-23)
    final judged = Searcher.process(rows, now: fetchedAt, windowDays: 30);
    expect(judged.quotes.any((q) => q.title.contains('ناودانی 8') && q.amount == 128000),
        isTrue);
    expect(judged.quotes.any((q) => q.title.contains('تیرآهن 14') && q.amount == 21000000),
        isTrue);
  });
}
