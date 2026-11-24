# گزارش تست نسخهٔ ۰.۹.۲۲ (build 44)

تاریخ اجرا: ۳ آذر ۱۴۰۵ (2026-11-24)

مرجع اجرای رسمی CI: **GitHub Actions** (`subosito/flutter-action@v2` — Flutter `3.24.5`، Dart `3.5.4`، Android SDK 35)

```text
flutter analyze              -> No issues found!
flutter test --concurrency=1 -> تمام آزمون‌های واحد، ویجت و یکپارچگی سبز (0 failed)
```

## موارد پوشش‌داده‌شده تا نسخهٔ `v0.9.22`

1. **مود رد کردن منابع اسکن‌شده تا `X` ساعت (`test/external_scanner_test.dart`)**:
   - صحت `MarketController.planRefreshQueue` با `preserveSourceOrder: true`: Skip شدن منابع اسکن‌شده در بازه `< X` ساعت و شروع مجدد از منبع اول پس از گذشت `X` ساعت.
   - آزمون یکپارچهٔ بستن و باز کردن دوبارهٔ برنامه (`MarketController` جدید روی همان `MarketStore`): حفظ `scan.skipMode`، `scan.skipHours` و `scan.scannedAtMap`، ادامهٔ اسکن بدون تکرار منابع قبلی، جلوگیری از درخواست اضافه هنگام تازه‌بودن همهٔ منابع، و شروع از اولین منبع پس از انقضای `X` ساعت.
2. **تفکیک «عدد (قطعه برش‌خورده)» از «برگ (شیت)» و «شاخه» (`test/product_converter_test.dart`)**:
   - آزمون‌های واحد و ویجت برای `SteelCalculator`، `ProductConverter` و `CalculatorPage` (محاسبه X عدد برش‌خورده با ابعاد/طول مشخص، چیدمان افقی/۹۰ درجه روی شیت، تعداد شیت/شاخه کامل موردنیاز، پرت برش و نرخ مجزای هر عدد در برابر هر شیت/شاخه).
3. **پایداری و کارایی در آرشیوهای بزرگ ۱۶٬۰۰۰ تا ۱۰۰٬۰۰۰ ردیفی (`test/scale_100k_test.dart`)**:
   - آزمون تایپ حرف‌به‌حرف نام در تب قیمت روی ۱۶٬۰۰۰ ردیف واقعی SQLite بدون کپی Isolate و بدون خطای UI.
4. **مجموعهٔ کامل آزمون‌های رگرسیون پروژه**:
   - تمام آزمون‌های قبلی قفل نوسازی (`refresh_lock_test.dart`)، موتور متن (`text_engine_test.dart`)، رنج‌گیری (`range_scope_test.dart`)، بکاپ، کش باینری و ویجت‌ها.

## ساخت APK و انتشار دو معماری (`v0.9.22`)

- `versionName='0.9.22'`, `versionCode='44'`, `minSdk=21`, `targetSdk=35`.
- فایل‌های نصبی `IronPin-0.9.22-armeabi-v7a-release.apk` و `IronPin-0.9.22-arm64-v8a-release.apk` همراه `SHA256SUMS.txt` در ریلیز `v0.9.22` با امضای ثابت پروژه ساخته و منتشر می‌شوند.
