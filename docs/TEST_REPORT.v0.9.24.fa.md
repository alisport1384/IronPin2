# گزارش تست نسخهٔ ۰.۹.۲۴ (build 46)

تاریخ اجرا: ۴ آذر ۱۴۰۵ (2026-11-25)

مرجع اجرای رسمی CI: **GitHub Actions** (`subosito/flutter-action@v2` — Flutter `3.24.5`، Dart `3.5.4`، Android SDK 35)

```text
flutter analyze              -> No issues found!
flutter test --concurrency=1 -> تمام آزمون‌های واحد، ویجت و یکپارچگی سبز (0 failed)
```

## موارد پوشش‌داده‌شده در آزمون‌های نسخه `v0.9.24` (`test/table_price_fixes_test.dart`)

1. استخراج مبلغ پایهٔ بدون ارزش افزوده (`33,000,000`, `1,579,500`, `114,039`) به‌عنوان عدد واقعی قیمت به‌جای برچسب «چند مبلغی».
2. تشخیص واحد `kg` (`کیلوگرم`) از سرستون `قیمت واحد وزن`.
3. نمایش عددی مبلغ پایه در `QuoteCard` حتی روی داده‌های ذخیره‌شدهٔ قبلی، و نبودن هیچ‌گونه برچسب `چند مبلغی`.

## ساخت APK و انتشار دو معماری (`v0.9.24`)

- `versionName='0.9.24'`, `versionCode='46'`, `minSdk=21`, `targetSdk=35`.
- فایل‌های نصبی `IronPin-0.9.24-armeabi-v7a-release.apk` و `IronPin-0.9.24-arm64-v8a-release.apk` همراه `SHA256SUMS.txt` در ریلیز `v0.9.24` منتشر می‌شوند.
