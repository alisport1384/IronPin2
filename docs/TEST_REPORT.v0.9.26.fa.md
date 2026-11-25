# گزارش تست نسخهٔ ۰.۹.۲۶ (build 48)

تاریخ اجرا: ۴ آذر ۱۴۰۵ (2026-11-25)

مرجع اجرای رسمی CI: **GitHub Actions** (`subosito/flutter-action@v2` — Flutter `3.24.5`، Dart `3.5.4`، Android SDK 35)

```text
flutter analyze              -> No issues found!
flutter test --concurrency=1 -> تمام آزمون‌های واحد، ویجت و یکپارچگی سبز (0 failed)
```

## موارد پوشش‌داده‌شده در نسخه `v0.9.26` (`test/product_converter_test.dart`, `test/widget_test.dart`)

1. ویجت‌تست باز شدن شیت راهنمای تصویری (`HelpBadge` / `showVisualHelp`) با `CustomPaint` بدون سرریز و خطا.
2. پوشش کامل تب‌های قیمت‌ها، نمودار، رنج‌گیری، ماشین حساب و اطلاعات با راهنمای تصویری معیارها.

## ساخت APK و انتشار دو معماری (`v0.9.26`)

- `versionName='0.9.26'`, `versionCode='48'`, `minSdk=21`, `targetSdk=35`.
- فایل‌های نصبی `IronPin-0.9.26-armeabi-v7a-release.apk` و `IronPin-0.9.26-arm64-v8a-release.apk` همراه `SHA256SUMS.txt` در ریلیز `v0.9.26` منتشر می‌شوند.
