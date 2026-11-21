import 'market.dart';
import 'product_text.dart';

/// Evidence-based fields shared by ingestion and the product-first range form.
/// Brand, seller, geography and tax never restrict product matching.
const productFields = <String, Map<String, String>>{
  'ورق': {
    'kind': 'نوع ورق',
    'thickness': 'ضخامت',
    'width': 'عرض',
    'length': 'طول',
    'grade': 'گرید',
    'material': 'جنس',
    'form': 'حالت عرضه',
    'dimensions': 'ابعاد',
    'dimUnit': 'واحد ابعاد'
  },
  'میلگرد بستر': {
    'width': 'عرض بستر',
    'size': 'قطر مفتول',
    'length': 'طول',
    'material': 'جنس',
    'coating': 'پوشش',
    'dimUnit': 'واحد ابعاد',
  },
  'میلگرد': {
    'size': 'قطر اسمی',
    'grade': 'گرید / آنالیز',
    'kind': 'نوع میلگرد',
    'length': 'طول',
    'material': 'جنس',
    'dimUnit': 'واحد ابعاد'
  },
  'تیرآهن': {
    'grade': 'استاندارد مقطع',
    'size': 'سایز / ارتفاع اسمی',
    'length': 'طول',
    'material': 'جنس',
    'dimUnit': 'واحد ابعاد'
  },
  'تیرچه': {
    'kind': 'نوع تیرچه (فلزی / بتنی)',
    'size': 'ارتفاع / سایز',
    'length': 'طول',
    'material': 'جنس',
    'grade': 'گرید فولاد',
    'mesh': 'شبکه / مفتول',
    'dimUnit': 'واحد ابعاد'
  },
  'نبشی': {
    'dimensions': 'دو بال',
    'thickness': 'ضخامت',
    'length': 'طول',
    'form': 'فابریک / پرسی',
    'material': 'جنس',
    'grade': 'گرید',
    'dimUnit': 'واحد ابعاد'
  },
  'ناودانی': {
    'size': 'ارتفاع اسمی',
    'thickness': 'ضخامت',
    'length': 'طول',
    'grade': 'استاندارد مقطع',
    'material': 'جنس',
    'dimUnit': 'واحد ابعاد'
  },
  'سپری': {
    'size': 'سایز',
    'thickness': 'ضخامت',
    'length': 'طول',
    'grade': 'گرید',
    'material': 'جنس',
    'dimUnit': 'واحد ابعاد'
  },
  'پروفیل': {
    'dimensions': 'ابعاد مقطع',
    'thickness': 'ضخامت',
    'kind': 'نوع مقطع',
    'length': 'طول',
    'material': 'جنس',
    'grade': 'گرید',
    'dimUnit': 'واحد ابعاد'
  },
  'لوله': {
    'size': 'قطر اسمی طبق منبع',
    'thickness': 'ضخامت',
    'kind': 'نوع لوله',
    'length': 'طول',
    'schedule': 'رده',
    'material': 'جنس',
    'grade': 'گرید',
    'dimUnit': 'واحد قطر / ابعاد'
  },
  'بولت': {
    'kind': 'نوع بولت / انکر (خام، L/J/U، مکانیکی، شیمیایی)',
    'size': 'قطر اسمی',
    'length': 'طول طبق منبع',
    'threadLength': 'طول رزوه',
    'pitch': 'گام رزوه',
    'grade': 'گرید / رده مقاومتی',
    'material': 'جنس',
    'coating': 'پوشش',
    'accessories': 'شمول مهره، واشر، چسب / ست',
    'model': 'مدل / تأییدیه سیستم',
    'embedment': 'عمق کاشت مؤثر',
    'lengthDeployed': 'طول بازشده روی محور',
    'massNote': 'وزن ست ≠ وزن بدنه',
    'torque': 'گشتاور',
    'dimUnit': 'واحد ابعاد',
  },
  'تسمه': {
    'form': 'فابریک / نوردی / برشی',
    'width': 'عرض',
    'thickness': 'ضخامت',
    'length': 'طول',
    'material': 'جنس',
    'grade': 'گرید',
    'cutPrice': 'قیمت برش سفارشی',
    'tolerance': 'تلرانس‌ها',
    'dimUnit': 'واحد ابعاد'
  },
  'چهارپهلو': {
    'size': 'ضلع',
    'length': 'طول',
    'material': 'جنس',
    'grade': 'گرید',
    'form': 'نوردی / ترانس',
    'areaFormula': 'فرمول مساحت مقطع',
    'hexKey': 'شش‌پر آچاری',
    'dimUnit': 'واحد ابعاد'
  },
  'مفتول': {
    'size': 'قطر سیم',
    'kind': 'نوع مفتول',
    'material': 'جنس',
    'grade': 'گرید',
    'coil': 'کلاف',
    'use': 'کاربرد',
    'dimUnit': 'واحد ابعاد'
  },
  'مش جوشی': {
    'size': 'قطر سیم',
    'mesh': 'چشمه',
    'dimensions': 'ابعاد برگ',
    'material': 'جنس',
    'massFormula': 'فرمول وزن برگ',
    'overlap': 'همپوشانی چشمه',
    'dimUnit': 'واحد ابعاد'
  },
  'توری': {
    'mesh': 'چشمه',
    'size': 'قطر سیم',
    'dimensions': 'ابعاد',
    'kind': 'نوع توری',
    'coating': 'پوشش',
    'material': 'جنس',
    'dimUnit': 'واحد ابعاد'
  },
  'رابیتس': {
    'columns': 'تعداد ستون',
    'mass': 'وزن اعلامی برگ',
    'massNote': 'یادداشت وزن (ستون به‌تنهایی وزن نمی‌دهد)',
    'dimensions': 'ابعاد',
    'material': 'جنس',
    'dimUnit': 'واحد ابعاد'
  },
  'شمش': {
    'grade': 'آنالیز',
    'exchange': 'حواله بورس / قیمت ارز',
    'dimensions': 'مقطع',
    'length': 'طول',
    'material': 'جنس',
    'dimUnit': 'واحد ابعاد'
  },
  'قراضه': {
    'kind': 'نوع / درجه قراضه',
    'material': 'جنس',
    'form': 'خرید / فروش',
    'contaminant': 'آلایش / ناخالصی',
    'deduction': 'کسری ناخالصی',
    'purity': 'خلوص'
  },
  'مواد اولیه فولاد': {
    'kind': 'گندله / آهن اسفنجی (DRI/HBI) / بریکت / فروآلیاژ',
    'grade': 'گرید یا آنالیز شیمیایی اعلام‌شده',
    'chemistry': 'درصد آهن کل، آهن فلزی، متالیزاسیون، کربن و ناخالصی طبق برگه آنالیز',
    'size': 'دانه‌بندی یا ابعاد طبق نوع و برگه آنالیز',
    'moisture': 'رطوبت اعلامی',
    'form': 'فله / کیسه / بریکت / کلوخه',
    'delivery': 'محل تحویل و مبنای باسکول',
    'unitBasis': 'تن یا کیلوگرم طبق اعلام منبع',
  },
};

/// One-line family definition shown above the range form: what the product
/// is, how it is sold and how it is normally calculated.
const productDefinitions = <String, String>{
  'ورق': 'صفحه فولادی تخت (سیاه/گرم، روغنی/سرد، گالوانیزه، آجدار)؛ فروش معمولاً کیلوگرم یا شیت؛ وزن از ضخامت × عرض × طول × 7.85 محاسبه می‌شود.',
  'میلگرد بستر': 'میلگرد مشبک آرماتوربندی (بستر) با مفتول جوش‌خورده؛ فروش شاخه/بند بر اساس عرض و قطر مفتول.',
  'میلگرد': 'میلگرد ساختمانی/صنعتی فولادی (ساده، آجدار، کلاف، ابزاری)؛ قیمت غالباً کیلوگرم و وزن از قطر (kg/m = d²/162.2) محاسبه می‌شود.',
  'تیرآهن': 'تیر فلزی IPE/INP/HEA/HEB؛ فروش شاخه یا کیلوگرم؛ وزن هر متر از جدول سایزِ مقطع است.',
  'تیرچه': 'تیرچه فلزی یا بتنی برای سقف تیرچه و بلوک؛ فروش شاخه/متر بر اساس ارتفاع و طول؛ نوع فلزی با شبکه فولادی مسلح می‌شود.',
  'نبشی': 'پروفیل زاویه‌ای دو بال (فابریک/پرسی)؛ فروش شاخه یا کیلوگرم.',
  'ناودانی': 'پروفیل ناودانی U شکل (UPN/UPE)؛ فروش شاخه یا کیلوگرم.',
  'سپری': 'پروفیل سپری T شکل؛ فروش شاخه یا کیلوگرم.',
  'پروفیل': 'قوطی مربع/مستطیل و مقاطع بسته؛ فروش شاخه/متر یا کیلوگرم.',
  'لوله': 'لوله فولادی (مانیسمان، درزدار، گالوانیزه، داربستی…) با رده Sch؛ فروش شاخه/متر یا کیلوگرم.',
  'بولت': 'پیچ و انکر فولادی (خام L/J/U، رول‌بولت، شیمیایی)؛ فروش عددی/ست؛ وزن ست با وزن بدنه فرق دارد.',
  'تسمه': 'نوار فولادی تخت (فابریک/برشی/ترانس)؛ فروش کیلوگرم یا شاخه؛ قیمت برش سفارشی جدا اعلام می‌شود.',
  'چهارپهلو': 'مقطع مربع/شش‌پر نوردی یا ترانس؛ فروش شاخه/کیلوگرم؛ وزن از ضلع (مربع: a² × 7.85 × طول).',
  'مفتول': 'سیم فولادی کلافی (بتن‌بند، آرماتور، گالوانیزه)؛ فروش کیلوگرم یا کلاف.',
  'مش جوشی': 'ورق مشبک جوش‌خورده برای آرماتور و فونداسیون؛ فروش برگ بر اساس چشمه و ابعاد.',
  'توری': 'توری فولادی (حصاری، مرغی، سرند، گابیون)؛ فروش رول/شیت بر اساس چشمه و قطر سیم.',
  'رابیتس': 'ورق مشبک رابیتس برای نمای گچی؛ فروش برگ بر اساس تعداد ستون و ابعاد.',
  'شمش': 'شمش/بیلت/بلوم/اسلب فولادی؛ فروش تن با مبنای حواله بورس کالا.',
  'قراضه': 'آهن قراضه سورت‌شده برای ذوب؛ فروش تن بر اساس درجه، خلوص و کسر آلایش.',
  'مواد اولیه فولاد': 'آهن اسفنجی (DRI/HBI)، گندله، بریکت و فروآلیاژ؛ فروش تن با مبنای برگه آنالیز و محل تحویل.',
};
String specNorm(String s) => ProductText.normalize(s)
    .toLowerCase()
    .replaceAll(RegExp(r'\s*[×*x]\s*'), 'x')
    .trim();

class ProductFacts {
  final String family;
  final Map<String, String> values;
  const ProductFacts(this.family, this.values);
  factory ProductFacts.of(Quote q) {
    final nonMetal = ProductText.isNonMetal('${q.title} ${q.category}');
    final family = nonMetal
        ? ''
        : ProductText.category(q.title).isNotEmpty
            ? ProductText.category(q.title)
            : ProductText.category(q.category);
    String field(String re) =>
        q.details.entries
            .where((e) => RegExp(re).hasMatch(latin(e.key)))
            .map((e) => latin(e.value))
            .firstOrNull ??
        '';
    final title = ProductText.normalize(q.title);
    final context = '$title ${field(r'^(?:نوع|پوشش|حالت|سطح مقطع)$')}';
    var kind = '';
    if (family == 'ورق') {
      kind = RegExp(r'گالوانیزه|روغنی|رنگی|آجدار|اسیدشویی|استیل|سیاه|سرد|گرم')
              .firstMatch(context)?[0] ??
          '';
      if (kind == 'گرم') kind = 'سیاه';
      if (kind == 'سرد') kind = 'روغنی';
    } else if (family == 'بولت') {
      kind = field(r'^نوع').isNotEmpty
          ? field(r'^نوع')
          : RegExp(r'مکانیکی|شیمیایی|خام|(?<![A-Za-z])[LJU](?![A-Za-z])',
                      caseSensitive: false)
                  .firstMatch(context)?[0] ??
              '';
    } else if (family == 'میلگرد') {
      kind = RegExp(r'آجدار|ساده|کلاف|بستر').firstMatch(context)?[0] ?? '';
    } else if (family == 'تیرچه') {
      kind = RegExp(r'فلزی|فولادی|بتنی|ترکیبی').firstMatch(context)?[0] ??
          field(r'^نوع');
    } else if (family == 'پروفیل') {
      kind = RegExp(r'مربع|مستطیل|مبلی|صنعتی|ستونی|درب|پنجره|[ZC](?![a-z])',
                  caseSensitive: false)
              .firstMatch(context)?[0] ??
          '';
    } else if (family == 'لوله') {
      kind =
          RegExp(r'مانیسمان|بدون درز|درزدار|داربستی|گازی|گالوانیزه|اسپیرال|جدار چاه|مبلی|صنعتی')
                  .firstMatch(context)?[0] ??
              '';
    } else if (family == 'مواد اولیه فولاد') {
      kind = RegExp(r'آهن\s*اسفنجی|\bDRI\b|\bHBI\b|گندله|بریکت|فرو\s*آلیاژ|pellet|briquette|ferroalloy', caseSensitive: false)
              .firstMatch(context)?[0] ?? field(r'^(?:نوع|درجه)$');
    } else {
      kind = field(r'^(?:نوع|درجه)$');
    }
    String capture(String label) =>
        RegExp('$label\\s*[:：]?\\s*(${ProductText.n})').firstMatch(title)?[1] ??
        '';
    final form =
        RegExp(r'فابریک|برشی|برش خورده|پرسی|رول|شیت|کلاف|شاخه|خرید|فروش|فله|کیسه|بریکت|کلوخه|نوردی|ترانس')
                .firstMatch(context)?[0] ??
            '';
    final unit = field(r'واحد ابعاد|واحد قطر');
    final dimUnit = unit.isNotEmpty
        ? unit
        : RegExp(r'میلی\s*متر|میلیمتر|سانتی\s*متر|اینچ|\bmm\b|\bcm\b|\binch\b',
                    caseSensitive: false)
                .firstMatch(title)?[0] ??
            '';
    // Numeric values without declared units remain in source units. No silent
    // metres/mm equivalence, pipe nominal-to-OD, or three-number reordering.
    String boltMeasure(String label) =>
        RegExp('$label\\s*[:：]?\\s*(${ProductText.n})(?:\\s*(میلی\\s*متر|میلیمتر|سانتی\\s*متر|متر|mm|cm|m))?',
                caseSensitive: false)
            .firstMatch(title)
            ?.group(0)
            ?.replaceFirst(RegExp('^$label\\s*[:：]?\\s*'), '') ??
        '';
    String technicalValue(String key, String label) {
      final explicit = field(label);
      if (explicit.isNotEmpty) return explicit;
      switch (key) {
        case 'coating':
          return RegExp(r'گالوانیزه گرم|گالوانیزه سرد|بدون پوشش|داکرومات')
                  .firstMatch(title)?[0] ??
              '';
        case 'accessories':
          return RegExp(
                      r'(?:با|بدون)\s+(?:مهره|واشر|چسب)(?:\s+و\s+(?:مهره|واشر|چسب))*|ست کامل|میله تنها')
                  .firstMatch(title)?[0] ??
              '';
        case 'threadLength':
          return boltMeasure('طول رزوه');
        case 'pitch':
          return boltMeasure('گام رزوه');
        default:
          return '';
      }
    }

    final values = <String, String>{
      'kind': kind,
      'size': q.sizeLabel.isNotEmpty
          ? q.sizeLabel
          : family == 'بولت'
              ? ProductText.spec(title).size
              : '',
      'thickness': q.thicknessLabel,
      'dimensions': q.dimensionsLabel,
      'grade': family == 'بولت'
          ? (field(r'گرید|رده مقاومتی').isNotEmpty
              ? field(r'گرید|رده مقاومتی')
              : RegExp(r'\b(?:[45689]\.[468]|10\.9|12\.9|F1554(?:\s*[-/:]?\s*(?:36|55|105))?)\b',
                          caseSensitive: false)
                      .firstMatch(title)?[0] ??
                  q.gradeLabel)
          : q.gradeLabel,
      if (family == 'بولت' || family == 'میلگرد بستر')
        for (final entry in const {
          'threadLength': 'طول رزوه',
          'pitch': 'گام رزوه',
          'coating': 'پوشش',
          'accessories': 'شمول|متعلقات',
          'model': 'مدل|تأییدیه',
          'embedment': 'عمق کاشت'
        }.entries)
          entry.key: technicalValue(entry.key, entry.value),
      // Legacy Quote defaults are not evidence for a selected material.
      'material': field(r'^(?:جنس|متریال)$').isNotEmpty
          ? field(r'^(?:جنس|متریال)$')
          : q.material != 'فولاد کربنی'
              ? q.material
              : RegExp(r'فولاد\s*کربنی|کربن\s*استیل|(?:ورق|پلیت|صفحه|میلگرد|تیر\s*آهن|تیرآهن|نبشی|ناودانی|پروفیل|لوله|تسمه)\s*(?:آهن\s*)?فولادی|آهن\s*فولادی')
                      .hasMatch(title)
                  ? 'فولاد کربنی'
                  : '',
      'width': field(r'^عرض(?:\s|\(|$)').isNotEmpty
          ? field(r'^عرض(?:\s|\(|$)')
          : capture('عرض'),
      'length': family == 'بولت'
          ? (field(r'^طول(?:\s*\([^)]*\))?$').isNotEmpty
              ? field(r'^طول(?:\s*\([^)]*\))?$')
              : boltMeasure('طول'))
          : field(r'^طول(?:\s|\(|$)').isNotEmpty
              ? field(r'^طول(?:\s|\(|$)')
              : (capture('طول').isNotEmpty
                  ? capture('طول')
                  : q.lengthM?.toString() ?? ''),
      'form': form,
      'dimUnit': dimUnit,
      'schedule': field('رده').isNotEmpty ? field('رده') : capture('رده'),
      'mesh': field('چشمه|شبکه|مفتول').isNotEmpty
            ? field('چشمه|شبکه|مفتول')
            : capture('چشمه'),
      'columns': field('ستون').isNotEmpty
          ? field('ستون')
          : RegExp('(${ProductText.n})\\s*ستون').firstMatch(title)?[1] ?? '',
      'mass': q.pieceKg?.toString() ?? field('وزن'),
      if (family == 'مواد اولیه فولاد') ...{
        'chemistry': field(r'آنالیز شیمیایی|ترکیب شیمیایی|آنالیز|FeT|Fe کل'),
        'moisture': field(r'رطوبت'),
        'delivery': field(r'محل تحویل|مبنای تحویل|تحویل'),
        'unitBasis': field(r'مبنای فروش|واحد فروش'),
      },
      if (family == 'تسمه') ...{
        'cutPrice': field(r'قیمت\s*برش|برش\s*سفارشی'),
        'tolerance': field(r'تلرانس'),
      },
      if (family == 'چهارپهلو') ...{
        'areaFormula': field(r'فرمول\s*مساحت|مساحت\s*مقطع'),
        'hexKey': field(r'شش\s*پر'),
      },
      if (family == 'مفتول') ...{
        'coil': field(r'کلاف'),
        'use': field(r'کاربرد|مصرف'),
      },
      if (family == 'مش جوشی') ...{
        'massFormula': field(r'فرمول\s*وزن|وزن\s*محاسباتی'),
        'overlap': field(r'همپوشانی|اورلپ|اوورلپ'),
      },
      if (family == 'توری') ...{
        'coating': field(r'پوشش|گالوانیزه'),
      },
      if (family == 'رابیتس') ...{
        'massNote': field(r'یادداشت\s*وزن|وزن\s*برگ'),
      },
      if (family == 'شمش') ...{
        'exchange': field(r'حواله\s*بورس|بورس\s*کالا'),
      },
      if (family == 'قراضه') ...{
        'contaminant': field(r'آلایش|ناخالصی'),
        'deduction': field(r'کسری|کسر\s*وزن'),
        'purity': field(r'خلوص'),
      },
      if (family == 'بولت') ...{
        'lengthDeployed': field(r'طول\s*بازشده|بازشده'),
        'massNote': field(r'وزن\s*ست'),
        'torque': field(r'گشتاور|تورک'),
      },
    };
    // Table dimensions can be the explicit section size (e.g. 40x40).
    if (values['dimensions']!.isEmpty &&
        ProductText.dimension.hasMatch(values['size']!)) {
      values['dimensions'] =
          ProductText.dimension.stringMatch(values['size']!)!;
    }
    return ProductFacts(family, values);
  }
  String get identity => [
        family,
        ...values.entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => '${e.key}:${specNorm(e.value)}')
      ].join('|');
  bool matches(Map<String, String> constraints) {
    for (final e in constraints.entries) {
      if (e.value.trim().isEmpty) continue;
      final actual = values[e.key] ?? '';
      if (actual.isEmpty) return false;
      final wanted = specNorm(e.value), value = specNorm(actual);
      if (wanted == value) continue;
      if (e.key == 'dimensions') {
        if (wanted.split('x').length == 2 &&
            wanted.split('x').reversed.join('x') == value) continue;
        return false;
      }
      if (ProductText.measureMatches(wanted, value)) continue;
      return false;
    }
    return true;
  }
}
