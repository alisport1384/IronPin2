# گزارش تست نسخهٔ ۰.۹.۱۵ (build 37)

تاریخ اجرا: ۳ آذر ۱۴۰۵ (2026-11-23)

مرجع اجرای رسمی CI: **GitHub Actions** (`subosito/flutter-action@v2` — Flutter `3.24.5`، Dart `3.5.4`، Android SDK 35)

```text
flutter analyze              -> No issues found!
flutter test --concurrency=1 -> تمام آزمون‌های واحد و یکپارچگی سبز (0 failed)
```

## چه چیزی سنجیده شد

- **کل مجموعهٔ آزمون‌های قبلی پروژه** (شامل کاتالوگ، پارسر فارسی، جستجوگر ۱ و ۲، رنج‌گیری، محاسبات هندسی، کش باینری، بکاپ JSONL، مقیاس ۱۰۰ هزار ردیف و ویجت‌های رابط کاربری) بدون شکست.
- **آزمون‌های جدید و به‌روزشدهٔ حالت خارجی (`test/external_scanner_test.dart`)**:
  - تجزیهٔ خروجی رسمی سرور `qwenscanner v2.0` در قالب `ironpin-sources-v1` (`GET /api/sources`).
  - فیلتر شدن منابع غیرخواندنی (`readable: false`) و تبدیل دقیق منابع خواندنی (`site`, `telegram`, `eitaa`, `bale`, `rubika`) به `Endpoint`های قابل اجرا در جستجوگر ۱ (`site-table`, `telegram`, `eitaa`, `bale`, `rubika`).
  - یکتاسازی منابع با `canonicalUrlKey` برای جلوگیری از اسکن تکراری یک دامنه یا کانال.
  - مهاجرت خودکار نشانی قدیمی `/api/ironpin` به `/api/sources` در `ExternalScanner.normalizeSourcesUrl`.
- **آزمایش زندهٔ هم‌کنش‌پذیری با سرور تولید (`https://qwen.alisport0.qzz.io/`)**:
  - پاسخ `GET /api/health`: `{"ok":true,"mode":"searcher2-only","version":"2.0.0"}`.
  - پاسخ `GET /api/sources`: بازگشت فهرست معتبر `ironpin-sources-v1` شامل وب‌سایت‌ها و کانال‌های تاییدشدهٔ بازار آهن با اطلاعات شهر، جدول قیمت و نشانی خواندنی.

## ساخت APK و انتشار دو معماری (`v0.9.15`)

- `versionName='0.9.15'`, `versionCode='37'`, `minSdk=21`, `targetSdk=35`.
- بیلد رسمی هر دو معماری روی GitHub Actions (ران `45160656493` روی تگ `v0.9.15` و ران `45160654095` روی `main`) با موفقیت کامل:
  - `IronPin-0.9.15-armeabi-v7a-release.apk` (`14,016,616` بایت — SHA-256: `1ffcf34cea33d1327f5f033378ff3b1a6220442239715ff6e27b9883253c9502`)
  - `IronPin-0.9.15-arm64-v8a-release.apk` (`14,621,539` بایت — SHA-256: `855586b102ec8dab45584fdc50870c81a1581688b3edb007e8006e751928f752`)
  - گواهی امضای ثابت پروژه (V2 Signer SHA-256): `c82917e03f78e6e2ef1104b58716690bef277c419fdd1c36f14140679cc993e9`
  - هر بسته تنها کتابخانهٔ بومی معماری خود به‌همراه هر دو مدل آفلاین OCR (`fas.traineddata` و `eng.traineddata`) را دارد.

## آزمایش‌نشده

- نصب و بررسی تعاملی فایل APK نهایی `v0.9.15` روی گوشی واقعی اندرویدی در حالت «اسکنر سرور (خارجی)» بر عهدهٔ کاربر است.
