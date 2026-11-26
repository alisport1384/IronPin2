# گزارش تست نسخهٔ ۰.۹.۲۷ (build 49)

تاریخ اجرا: ۴ آذر ۱۴۰۵ (2026-11-25)

مرجع اجرای رسمی CI: **GitHub Actions** (`subosito/flutter-action@v2` — Flutter `3.24.5`، Dart `3.5.4`، Android SDK 35)

```text
flutter analyze              -> No issues found!
flutter test --concurrency=1 -> تمام آزمون‌های واحد، ویجت و یکپارچگی سبز (0 failed)
```

## موارد پوشش‌داده‌شده در نسخه `v0.9.27` (`test/product_converter_test.dart`)

1. آزمون واحد `ProductConverter.convertCutPiece`: محاسبه وزن خالص برش‌خورده بدون وابستگی به ابعاد شیت/شاخه فابریک، و افزودن وزن پرت به بهای پایه کالا هنگام فعال بودن `includeWasteInBaseCost`.
2. آزمون ویجت `CutCalculatorView`: مخفی بودن ورودی‌های شیت فابریک در حالت پیش‌فرض، نمایش وزن تک‌قطعه و وزن کل، و باز شدن تنظیمات تأمین و پرت با کلید روشن/خاموش.
