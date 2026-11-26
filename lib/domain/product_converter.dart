import 'dart:math' as math;
import 'calculator.dart';

class MetalAlloy {
  final String id, label;
  final double density; // kg/m³
  const MetalAlloy(this.id, this.label, this.density);
}

const metalAlloys = <MetalAlloy>[
  MetalAlloy('steel', 'فولاد کربنی / آهن (سیاه، آجدار، گالوانیزه)', 7850),
  MetalAlloy('ss304', 'استیل ۳۰۴ / ۳۰۴L (ضدزنگ)', 7900),
  MetalAlloy('ss316', 'استیل ۳۱۶ / ۳۱۶L', 8000),
  MetalAlloy('ss430', 'استیل ۴۳۰', 7700),
  MetalAlloy('aluminum', 'آلومینیوم', 2700),
  MetalAlloy('copper', 'مس', 8960),
  MetalAlloy('brass', 'برنج', 8500),
  MetalAlloy('cast_iron', 'چدن', 7200),
  MetalAlloy('custom', 'جنس دلخواه (چگالی سفارشی)', 7850),
];

class ConverterField {
  final String key, label;
  final double initial;
  final bool allowZero;
  final bool integerOnly;
  const ConverterField(
    this.key,
    this.label,
    this.initial, {
    this.allowZero = false,
    this.integerOnly = false,
  });
}

class ConverterProductSpec {
  final String id, title, subtitle, pieceLabel, bundleLabel, note;
  final bool hasMetres, hasArea, usesDensity, supportsCutCount;
  final List<ConverterField> fields;
  const ConverterProductSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.pieceLabel,
    required this.bundleLabel,
    required this.hasMetres,
    required this.hasArea,
    required this.usesDensity,
    this.supportsCutCount = false,
    required this.fields,
    required this.note,
  });

  List<String> get supportedUnits => [
        if (hasMetres) 'm',
        if (hasArea) 'm2',
        'kg',
        'ton',
        'piece',
        if (supportsCutCount) 'cut',
        'bundle',
      ];
}

const converterProducts = <ConverterProductSpec>[
  ConverterProductSpec(
    id: 'plate',
    title: 'ورق (سیاه، گالوانیزه، روغنی، استیل...)',
    subtitle: 'ضخامت، عرض، طول برگ، جنس و تعداد در بسته',
    pieceLabel: 'برگ (شیت)',
    bundleLabel: 'بسته / پالت',
    hasMetres: true,
    hasArea: true,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('thicknessMm', 'ضخامت ورق (میلی‌متر)', 2),
      ConverterField('widthMm', 'عرض شیت فابریک (میلی‌متر؛ مثلاً ۱۲۵۰ یا ۱۰۰۰)', 1250),
      ConverterField('pieceLengthM', 'طول هر برگ / شیت (متر؛ مثلاً ۲٫۵ یا ۲)', 2.5),
      ConverterField('coatGsm', 'جرم پوشش دو رو (گرم بر مترمربع؛ صفر = بدون پوشش)', 0,
          allowZero: true),
      ConverterField('piecesPerBundle', 'تعداد برگ در هر بسته / پالت', 20),
    ],
    note:
        'وزن = طول × عرض × ضخامت × چگالی جنس (+ پوشش اعلامی). «برگ (شیت)» مربوط به ورق کامل و «عدد» مربوط به قطعات برش‌خورده با عرض و طول مشخص است.',
  ),
  ConverterProductSpec(
    id: 'rebar',
    title: 'میلگرد (ساده، آجدار، استیل)',
    subtitle: 'قطر، جنس، طول شاخه و تعداد در بندیل',
    pieceLabel: 'شاخه',
    bundleLabel: 'بندیل / دسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('diameterMm', 'قطر / سایز میلگرد (میلی‌متر)', 16),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر؛ معمولاً ۱۲)', 12),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بندیل / دسته', 100),
    ],
    note:
        'تعداد شاخه در هر بندیل بسته به کارخانه و سایز متفاوت است (معمولاً بین ۵۰ تا ۴۵۰ شاخه؛ حدود ۲ تا ۵٫۵ تن). برای محاسبه قطعه برش‌خورده با طول دلخواه، واحد «عدد» را انتخاب کنید.',
  ),
  ConverterProductSpec(
    id: 'rhs',
    title: 'پروفیل و قوطی (مربع / مستطیل)',
    subtitle: 'ارتفاع، عرض، ضخامت، جنس، طول شاخه و بسته',
    pieceLabel: 'شاخه',
    bundleLabel: 'بسته / بندیل',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('heightMm', 'ارتفاع / ضلع اول (میلی‌متر)', 40),
      ConverterField('widthMm', 'عرض / ضلع دوم (میلی‌متر)', 40),
      ConverterField('thicknessMm', 'ضخامت جداره (میلی‌متر)', 2),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر؛ معمولاً ۶)', 6),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بسته / دسته', 12),
    ],
    note: 'محاسبه هندسی بر پایه مقطع بسته گوشه‌تیز و جنس انتخابی.',
  ),
  ConverterProductSpec(
    id: 'pipe',
    title: 'لوله (سیاه، گازی، مانیسمان، استیل، مس...)',
    subtitle: 'قطر خارجی، ضخامت، جنس، طول شاخه و بسته',
    pieceLabel: 'شاخه',
    bundleLabel: 'بسته / بندیل',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('odMm', 'قطر خارجی واقعی (میلی‌متر؛ نه نمره اینچی)', 48.3),
      ConverterField('thicknessMm', 'ضخامت جداره (میلی‌متر)', 2),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر؛ معمولاً ۶)', 6),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بسته / دسته', 10),
    ],
    note: 'از قطر خارجی واقعی (OD) و ضخامت استفاده کنید؛ نمره اینچی به‌تنهایی قطر خارجی نیست.',
  ),
  ConverterProductSpec(
    id: 'flat',
    title: 'تسمه (فولادی، استیل، مس، آلومینیوم)',
    subtitle: 'عرض، ضخامت، جنس، طول شاخه و دسته',
    pieceLabel: 'شاخه',
    bundleLabel: 'دسته / بسته',
    hasMetres: true,
    hasArea: true,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('widthMm', 'عرض تسمه (میلی‌متر)', 50),
      ConverterField('thicknessMm', 'ضخامت تسمه (میلی‌متر)', 5),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر)', 6),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر دسته / بسته', 20),
    ],
    note: 'مساحت معادل سطح یک رو (عرض × متراژ) بر حسب مترمربع است.',
  ),
  ConverterProductSpec(
    id: 'angle',
    title: 'نبشی (بال مساوی / نامساوی)',
    subtitle: 'دو بال، ضخامت، جنس، طول شاخه و بندیل',
    pieceLabel: 'شاخه',
    bundleLabel: 'بندیل / دسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('leg1Mm', 'اندازه بال اول (میلی‌متر)', 50),
      ConverterField('leg2Mm', 'اندازه بال دوم (میلی‌متر)', 50),
      ConverterField('thicknessMm', 'ضخامت بال (میلی‌متر)', 5),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر؛ ۶ یا ۱۲)', 6),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بندیل / دسته', 20),
    ],
    note: 'تقریب هندسی L شکل با حذف هم‌پوشانی گوشه.',
  ),
  ConverterProductSpec(
    id: 'channel',
    title: 'ناودانی (ابعاد مقطع)',
    subtitle: 'ارتفاع، عرض بال، ضخامت جان و بال، جنس و بسته',
    pieceLabel: 'شاخه',
    bundleLabel: 'بندیل / دسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('heightMm', 'ارتفاع کل (میلی‌متر)', 100),
      ConverterField('widthMm', 'عرض بال (میلی‌متر)', 50),
      ConverterField('webMm', 'ضخامت جان (میلی‌متر)', 6),
      ConverterField('flangeMm', 'ضخامت بال (میلی‌متر)', 8),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر؛ ۶ یا ۱۲)', 6),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بندیل / دسته', 10),
    ],
    note: 'برای ناودانی با بال شیب‌دار، وزن کاتالوگ سازنده دقیق‌تر است.',
  ),
  ConverterProductSpec(
    id: 'ibeam_geom',
    title: 'تیرآهن I / H (محاسبه با ابعاد جان و بال و جنس)',
    subtitle: 'ارتفاع، عرض بال، ضخامت جان و بال، جنس، شاخه و بندیل',
    pieceLabel: 'شاخه',
    bundleLabel: 'بندیل / دسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('heightMm', 'ارتفاع کل مقطع (میلی‌متر)', 180),
      ConverterField('widthMm', 'عرض بال (میلی‌متر)', 91),
      ConverterField('webMm', 'ضخامت جان (میلی‌متر)', 5.3),
      ConverterField('flangeMm', 'ضخامت بال (میلی‌متر)', 8),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر؛ معمولاً ۱۲)', 12),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بندیل / دسته', 6),
    ],
    note: 'محاسبه هندسی بدون شعاع ریشه؛ برای تطبیق دقیق با کارخانه، گزینه «بر مبنای وزن هر متر کاتالوگ» را انتخاب کنید.',
  ),
  ConverterProductSpec(
    id: 'beam',
    title: 'تیرآهن IPE (استاندارد و سبک)',
    subtitle: 'جدول سایزهای ۸ تا ۴۰ اشتال / سبک یا وزن هر متر',
    pieceLabel: 'شاخه',
    bundleLabel: 'بندیل / دسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: false,
    supportsCutCount: true,
    fields: [
      ConverterField('kgPerMetre', 'وزن هر متر تیرآهن (کیلوگرم بر متر)', 16.0),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر؛ معمولاً ۱۲)', 12),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بندیل / دسته', 6),
    ],
    note:
        'تیرآهن IPE از جدول اشتال (مثل سایز ۱۴=۱۵۵ کگ، ۱۶=۱۹۲ کگ، ۱۸=۲۲۶ کگ در ۱۲ متر) یا سبک متفرقه انتخاب می‌شود؛ همیشه وزن واقعی باسکول مبنای تسویه است.',
  ),
  ConverterProductSpec(
    id: 'hbeam',
    title: 'تیرآهن هاش ستونی (سبک HEA / سنگین HEB)',
    subtitle: 'جدول هاش ۱۰ تا ۴۰ سبک و سنگین یا وزن هر متر',
    pieceLabel: 'شاخه',
    bundleLabel: 'بندیل / دسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: false,
    supportsCutCount: true,
    fields: [
      ConverterField('kgPerMetre', 'وزن هر متر هاش (کیلوگرم بر متر)', 42.33),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر؛ معمولاً ۱۲)', 12),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بندیل / دسته', 4),
    ],
    note:
        'در هاش با سایز مساوی، مدل سبک (HEA) بال و جان نازک‌تر و مدل سنگین (HEB) بال و جان ضخیم‌تر دارد.',
  ),
  ConverterProductSpec(
    id: 'catalog_kgm',
    title: 'تیرآهن، هاش، ریل یا مقطع با وزن هر متر کاتالوگ',
    subtitle: 'وزن هر متر جدول، طول شاخه و تعداد در بندیل',
    pieceLabel: 'شاخه',
    bundleLabel: 'بندیل / دسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: false,
    supportsCutCount: true,
    fields: [
      ConverterField('kgPerMetre', 'وزن هر متر از جدول سازنده (کیلوگرم بر متر)', 18.8),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر؛ معمولاً ۱۲)', 12),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بندیل / دسته', 6),
    ],
    note: 'دقیق‌ترین روش برای تیرآهن IPE/IPN/HEA/HEB، ناودانی UPN یا مقاطع خاص Z/C.',
  ),
  ConverterProductSpec(
    id: 'tee',
    title: 'سپری',
    subtitle: 'ارتفاع، عرض بال، ضخامت جان و بال، جنس و دسته',
    pieceLabel: 'شاخه',
    bundleLabel: 'دسته / بسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('heightMm', 'ارتفاع کل (میلی‌متر)', 50),
      ConverterField('widthMm', 'عرض بال (میلی‌متر)', 50),
      ConverterField('webMm', 'ضخامت جان (میلی‌متر)', 5),
      ConverterField('flangeMm', 'ضخامت بال (میلی‌متر)', 5),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر)', 6),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر دسته', 12),
    ],
    note: 'محاسبه هندسی سپری با بال و جان مستطیلی و جنس انتخابی.',
  ),
  ConverterProductSpec(
    id: 'bar',
    title: 'چهارپهلو / شمش / بیلت مستطیلی',
    subtitle: 'ارتفاع، عرض، جنس، طول شاخه و دسته',
    pieceLabel: 'شاخه',
    bundleLabel: 'دسته / بندیل',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('heightMm', 'ارتفاع (میلی‌متر)', 40),
      ConverterField('widthMm', 'عرض (میلی‌متر)', 40),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر)', 6),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر دسته', 10),
    ],
    note: 'مناسب چهارپهلو فولادی، استیل، مس و آلومینیوم.',
  ),
  ConverterProductSpec(
    id: 'hex',
    title: 'شش‌پر توپر',
    subtitle: 'فاصله دو وجه موازی، جنس، طول شاخه و دسته',
    pieceLabel: 'شاخه',
    bundleLabel: 'دسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('flatToFlatMm', 'فاصله دو وجه موازی آچارخور (میلی‌متر)', 30),
      ConverterField('pieceLengthM', 'طول هر شاخه (متر)', 6),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر دسته', 10),
    ],
    note: 'اندازه ورودی فاصله دو وجه موازی است، نه فاصله دو رأس.',
  ),
  ConverterProductSpec(
    id: 'wire',
    title: 'مفتول / سیم (کلافی)',
    subtitle: 'قطر مفتول، جنس، متراژ هر کلاف و تعداد در بسته',
    pieceLabel: 'کلاف / حلقه',
    bundleLabel: 'بسته / پالت',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('diameterMm', 'قطر مفتول (میلی‌متر)', 2.5),
      ConverterField('pieceLengthM', 'متراژ یک کلاف / حلقه (متر)', 100),
      ConverterField('piecesPerBundle', 'تعداد کلاف در هر بسته / پالت', 10),
    ],
    note: 'متراژ مفتول، وزن، تعداد کلاف و پالت با یکدیگر تبدیل می‌شوند.',
  ),
  ConverterProductSpec(
    id: 'mesh',
    title: 'مش جوشی',
    subtitle: 'طول و عرض پنل، قطر و تعداد سیم‌ها، جنس و بسته',
    pieceLabel: 'برگ / پنل',
    bundleLabel: 'بسته / دسته',
    hasMetres: false,
    hasArea: true,
    usesDensity: true,
    fields: [
      ConverterField('panelWidthM', 'عرض پنل (متر)', 2),
      ConverterField('panelLengthM', 'طول پنل (متر)', 3),
      ConverterField('dxMm', 'قطر سیم طولی (میلی‌متر)', 6),
      ConverterField('dyMm', 'قطر سیم عرضی (میلی‌متر)', 6),
      ConverterField('nx', 'تعداد سیم‌های طولی در عرض پنل', 11, integerOnly: true),
      ConverterField('ny', 'تعداد سیم‌های عرضی در طول پنل', 16, integerOnly: true),
      ConverterField('piecesPerBundle', 'تعداد پنل در هر بسته', 10),
    ],
    note: 'تبدیل بین تعداد پنل، مترمربع، کیلوگرم، تن و بسته.',
  ),
  ConverterProductSpec(
    id: 'piece_pack',
    title: 'رابیتس / توری / قطعه بسته‌ای',
    subtitle: 'وزن و مساحت هر برگ/رول و تعداد در بسته',
    pieceLabel: 'برگ / رول',
    bundleLabel: 'بسته / دسته',
    hasMetres: false,
    hasArea: true,
    usesDensity: false,
    fields: [
      ConverterField('kgPerPiece', 'وزن یک برگ / رول (کیلوگرم)', 0.9),
      ConverterField('areaPerPieceM2', 'مساحت یک برگ / رول (مترمربع)', 1.44),
      ConverterField('piecesPerBundle', 'تعداد برگ / رول در هر بسته', 10),
    ],
    note: 'تبدیل دقیق بر اساس وزن و مساحت واقعی اعلام‌شده برای هر برگ یا رول.',
  ),
  ConverterProductSpec(
    id: 'cut_plate',
    title: 'صفحه ستون، پلیت و قطعه ورق (بر مبنای عدد)',
    subtitle: 'ضخامت، عرض، طول قطعه، جنس و تعداد عدد در بسته',
    pieceLabel: 'عدد',
    bundleLabel: 'بسته / پالت',
    hasMetres: false,
    hasArea: true,
    usesDensity: true,
    fields: [
      ConverterField('thicknessMm', 'ضخامت قطعه (میلی‌متر)', 10),
      ConverterField('widthMm', 'عرض قطعه (میلی‌متر)', 300),
      ConverterField('lengthMm', 'طول قطعه (میلی‌متر)', 300),
      ConverterField('piecesPerBundle', 'تعداد عدد در هر بسته / پالت', 10),
    ],
    note: 'وزن هر عدد = طول × عرض × ضخامت × چگالی جنس؛ مناسب پلیت، بیس‌پلیت، لچکی و قطعات برش‌خورده با واحد عدد.',
  ),
  ConverterProductSpec(
    id: 'unit_item',
    title: 'قطعه تکی / اتصالات / مهره و واشر (با وزن هر عدد)',
    subtitle: 'وزن هر یک عدد و تعداد در کارتن یا بسته',
    pieceLabel: 'عدد',
    bundleLabel: 'بسته / کارتن',
    hasMetres: false,
    hasArea: false,
    usesDensity: false,
    fields: [
      ConverterField('kgPerPiece', 'وزن هر یک عدد (کیلوگرم)', 2.5),
      ConverterField('piecesPerBundle', 'تعداد عدد در هر بسته / کارتن', 10),
    ],
    note: 'مناسب فلنج، زانویی، سه‌راهی، پیچ و مهره، بولت و هر کالایی که بر مبنای تعداد عدد و وزن واحد قیمت‌گذاری یا معامله می‌شود.',
  ),
  ConverterProductSpec(
    id: 'mesh_area',
    title: 'توری (پرسی، حصاری، گابیون — بر مبنای مترمربع)',
    subtitle: 'وزن هر مترمربع، مساحت برگ/رول و تبدیل دوطرفه مترمربع ↔ کیلو',
    pieceLabel: 'برگ / رول',
    bundleLabel: 'بسته / دسته',
    hasMetres: false,
    hasArea: true,
    usesDensity: false,
    fields: [
      ConverterField('kgPerM2', 'وزن یک مترمربع توری (کیلوگرم بر مترمربع)', 2.0),
      ConverterField('areaPerPieceM2', 'مساحت هر برگ یا رول (مترمربع؛ مثلاً ۲ یا ۱۰)', 2.0),
      ConverterField('piecesPerBundle', 'تعداد برگ / رول در هر بسته', 10),
    ],
    note:
        'مناسب سفارش‌های متراژی توری (مثلاً ۱۱ مترمربع): بر اساس وزن هر مترمربع، وزن کل، تعداد برگ/رول و بسته فوراً محاسبه می‌شود و برعکس.',
  ),
  ConverterProductSpec(
    id: 'stud',
    title: 'گل‌میخ (برشگیر سقف عرشه فولادی)',
    subtitle: 'قطر، طول، جنس و تعداد در کارتن (بدون نیاز به حدس فروشنده)',
    pieceLabel: 'عدد',
    bundleLabel: 'کارتن / بسته',
    hasMetres: false,
    hasArea: false,
    usesDensity: true,
    fields: [
      ConverterField('diameterMm', 'قطر بدنه گل‌میخ (میلی‌متر؛ رایج ۱۹)', 19),
      ConverterField('lengthMm', 'طول گل‌میخ (میلی‌متر؛ رایج ۱۰۰)', 100),
      ConverterField('piecesPerBundle', 'تعداد عدد در هر کارتن / بسته', 80),
    ],
    note:
        'در بازار ایران اغلب بدون ذکر ابعاد قیمت می‌دهند چون سایز ۱۹×۱۰۰ میلی‌متر (حدود ۲۶۲ گرم هر عدد) متداول است؛ برای دقت، قطر (۱۳/۱۶/۱۹/۲۲/۲۵) و طول (۵۰ تا ۲۰۰) را مشخص کنید.',
  ),
  ConverterProductSpec(
    id: 'wallpost',
    title: 'وال‌پست (ورقی خم‌کاری / منقطع / کشویی)',
    subtitle: 'ضخامت، عرض بازشده ورق یا وزن واحد؛ تبدیل کیلو ↔ متر ↔ شاخه',
    pieceLabel: 'شاخه / عدد',
    bundleLabel: 'بسته / دسته',
    hasMetres: true,
    hasArea: true,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('thicknessMm', 'ضخامت ورق وال‌پست (میلی‌متر؛ مثلاً ۲)', 2),
      ConverterField('widthMm', 'عرض بازشده ورق یا مجموع بال و جان (میلی‌متر؛ مثلاً ۲۵۰)', 250),
      ConverterField('pieceLengthM', 'طول هر شاخه / قطعه (متر؛ معمولاً ۳ یا ۶)', 3),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بسته', 10),
    ],
    note:
        'اگر وال‌پست با ناودانی/نبشی/قوطی است می‌توانید همان مقطع را انتخاب کنید؛ برای وال‌پست ورقی، با ورود کیلوگرم یا متر هر دو معادل محاسبه می‌شوند.',
  ),
  ConverterProductSpec(
    id: 'gutter',
    title: 'آبرو (شیروانی، جعبه‌ای، لندنی، فیتیله‌ای)',
    subtitle: 'ضخامت ورق، عرض برش (سانت/میل)، متراژ و تبدیل وزن ↔ متر',
    pieceLabel: 'شاخه',
    bundleLabel: 'بسته / دسته',
    hasMetres: true,
    hasArea: true,
    usesDensity: true,
    supportsCutCount: true,
    fields: [
      ConverterField('thicknessMm', 'ضخامت ورق آبرو (میلی‌متر؛ مثلاً ۱ یا ۱٫۵)', 1),
      ConverterField('widthMm', 'عرض برش ورق پیش از خم (میلی‌متر؛ مثلاً ۴۱۰ یا ۵۰۰)', 500),
      ConverterField('coatGsm', 'جرم پوشش گالوانیزه (گرم بر مترمربع؛ صفر = بدون پوشش جدا)', 0,
          allowZero: true),
      ConverterField('pieceLengthM', 'طول هر شاخه آبرو (متر؛ معمولاً ۶ یا ۳)', 6),
      ConverterField('piecesPerBundle', 'تعداد شاخه در هر بسته', 10),
    ],
    note:
        'وزن آبرو از عرض برش ورق پیش از خم و ضخامت ورق محاسبه می‌شود؛ با ورود متراژ (متر) وزن و شاخه به دست می‌آید و برعکس.',
  ),
  ConverterProductSpec(
    id: 'ghameh',
    title: 'قامه / بولت عصایی / انکر خم‌دار (با رزوه و مهره)',
    subtitle: 'قطر میلگرد، طول بازشده، جرم متعلقات (مهره و واشر) و تبدیل متر ↔ عدد',
    pieceLabel: 'عدد',
    bundleLabel: 'بسته / دسته',
    hasMetres: true,
    hasArea: false,
    usesDensity: true,
    supportsCutCount: false,
    fields: [
      ConverterField('diameterMm', 'قطر میلگرد قامه / بولت (میلی‌متر؛ مثلاً ۱۶ یا ۱۸)', 16),
      ConverterField('pieceLengthM', 'طول بازشده هر عدد روی محور خم (متر؛ مثلاً ۰٫۶)', 0.6),
      ConverterField('accessoriesKg', 'جرم مهره و واشر هر عدد (کیلوگرم؛ صفر = بدون مهره)', 0,
          allowZero: true),
      ConverterField('piecesPerBundle', 'تعداد عدد در هر بسته', 25),
    ],
    note:
        'طول هر قامه باید طول بازشده قبل از خم باشد. اگر خدمات رزوه، خم‌کاری یا مهره جدا حساب می‌شود از بخش خدمات پایین استفاده کنید.',
  ),
];

class ProductConversionResult {
  final ConverterProductSpec spec;
  final double density;
  final double kgPerMetre;
  final double kgPerPiece;
  final double kgPerBundle;
  final double areaPerPiece;
  final double piecesPerBundle;
  final double pieceLengthM;
  final double totalKg;
  final double totalTon;
  final double totalMetres;
  final double totalAreaM2;
  final double totalPieces;
  final double totalBundles;
  final double kgPerCut;
  final double totalCuts;
  final CutAllocationResult? cutAllocation;

  const ProductConversionResult({
    required this.spec,
    required this.density,
    required this.kgPerMetre,
    required this.kgPerPiece,
    required this.kgPerBundle,
    required this.areaPerPiece,
    required this.piecesPerBundle,
    required this.pieceLengthM,
    required this.totalKg,
    required this.totalTon,
    required this.totalMetres,
    required this.totalAreaM2,
    required this.totalPieces,
    required this.totalBundles,
    this.kgPerCut = 0,
    this.totalCuts = 0,
    this.cutAllocation,
  });

  /// Breaks total pieces into whole bundles + remaining pieces.
  ({int wholeBundles, double remainingPieces}) get bundleBreakdown {
    if (piecesPerBundle <= 0) return (wholeBundles: 0, remainingPieces: totalPieces);
    final whole = (totalPieces + 1e-9) ~/ piecesPerBundle;
    final rem = math.max(0.0, totalPieces - whole * piecesPerBundle);
    return (wholeBundles: whole, remainingPieces: rem);
  }
}

class OrderServiceInput {
  final String name;
  final String unit; // kg, ton, m, m2, piece, cut, bundle, manual, flat
  final double? manualQuantity;
  final double unitPrice;

  const OrderServiceInput({
    required this.name,
    required this.unit,
    this.manualQuantity,
    required this.unitPrice,
  });
}

class OrderServiceLine {
  final String name;
  final String unit;
  final double effectiveQuantity;
  final double unitPrice;
  final double lineTotal;

  const OrderServiceLine({
    required this.name,
    required this.unit,
    required this.effectiveQuantity,
    required this.unitPrice,
    required this.lineTotal,
  });
}

class OrderCostResult {
  final double baseUnitPrice;
  final String basePriceUnit;
  final double baseQuantity;
  final double baseCost;
  final List<OrderServiceLine> serviceLines;
  final double servicesTotal;
  final double shipping;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final double? finalPerKg;
  final double? finalPerMetre;
  final double? finalPerPiece;

  const OrderCostResult({
    required this.baseUnitPrice,
    required this.basePriceUnit,
    required this.baseQuantity,
    required this.baseCost,
    required this.serviceLines,
    required this.servicesTotal,
    required this.shipping,
    required this.taxPercent,
    required this.taxAmount,
    required this.grandTotal,
    this.finalPerKg,
    this.finalPerMetre,
    this.finalPerPiece,
  });
}

class ProductConverter {
  static String unitLabel(ConverterProductSpec spec, String unit) => switch (unit) {
        'm' => 'متر',
        'm2' => 'مترمربع',
        'kg' => 'کیلوگرم',
        'ton' => 'تن',
        'piece' => spec.pieceLabel,
        'cut' => 'عدد (قطعه برش‌خورده)',
        'bundle' => spec.bundleLabel,
        'manual' => 'عدد کار (دستی)',
        'flat' => 'مبلغ ثابت کل',
        _ => unit,
      };

  static double unitQuantityFromResult(ProductConversionResult res, String unit) =>
      switch (unit) {
        'm' => res.totalMetres,
        'm2' => res.totalAreaM2,
        'kg' => res.totalKg,
        'ton' => res.totalTon,
        'piece' => res.totalPieces,
        'cut' => res.totalCuts,
        'bundle' => res.totalBundles,
        'flat' => 1.0,
        _ => 0.0,
      };

  static OrderCostResult calculateOrderCost({
    required ProductConversionResult conversion,
    required String basePriceUnit,
    double? baseUnitPrice,
    List<OrderServiceInput> services = const [],
    double shipping = 0,
    double taxPercent = 0,
    bool taxIncludesServices = true,
    bool includeWasteInBaseCost = false,
  }) {
    if (baseUnitPrice != null && (!baseUnitPrice.isFinite || baseUnitPrice < 0)) {
      throw const FormatException('قیمت پایه نمی‌تواند منفی باشد.');
    }
    if (!shipping.isFinite || shipping < 0) {
      throw const FormatException('کرایه حمل نمی‌تواند منفی باشد.');
    }
    if (!taxPercent.isFinite || taxPercent < 0) {
      throw const FormatException('درصد مالیات نمی‌تواند منفی باشد.');
    }
    double baseQty = unitQuantityFromResult(conversion, basePriceUnit);
    final alloc = conversion.cutAllocation;
    if (includeWasteInBaseCost && alloc != null && alloc.fitsInStock) {
      baseQty = switch (basePriceUnit) {
        'kg' => alloc.stockTotalKg,
        'ton' => alloc.stockTotalKg / 1000.0,
        'm2' => alloc.requiredStockPieces * conversion.areaPerPiece,
        'm' => alloc.requiredStockPieces * conversion.pieceLengthM,
        'piece' => alloc.requiredStockPieces.toDouble(),
        _ => baseQty,
      };
    }
    final basePrice = baseUnitPrice ?? 0.0;
    final baseCost = baseQty > 0 ? baseQty * basePrice : 0.0;

    final lines = <OrderServiceLine>[];
    var servicesTotal = 0.0;
    for (final s in services) {
      if (!s.unitPrice.isFinite || s.unitPrice < 0) {
        throw FormatException('نرخ خدمت «${s.name}» معتبر نیست.');
      }
      final double effQty;
      if (s.unit == 'flat') {
        effQty = 1.0;
      } else if (s.unit == 'manual') {
        final mq = s.manualQuantity ?? 0;
        if (!mq.isFinite || mq < 0) {
          throw FormatException('مقدار خدمت «${s.name}» معتبر نیست.');
        }
        effQty = mq;
      } else if (s.manualQuantity != null) {
        if (!s.manualQuantity!.isFinite || s.manualQuantity! < 0) {
          throw FormatException('مقدار خدمت «${s.name}» معتبر نیست.');
        }
        effQty = s.manualQuantity!;
      } else {
        effQty = unitQuantityFromResult(conversion, s.unit);
      }
      final lineTotal = effQty * s.unitPrice;
      servicesTotal += lineTotal;
      lines.add(OrderServiceLine(
        name: s.name.trim().isEmpty ? 'خدمت' : s.name.trim(),
        unit: s.unit,
        effectiveQuantity: effQty,
        unitPrice: s.unitPrice,
        lineTotal: lineTotal,
      ));
    }

    final taxableBase =
        taxIncludesServices ? (baseCost + servicesTotal) : baseCost;
    final taxAmount = taxableBase * (taxPercent / 100.0);
    final grandTotal = baseCost + servicesTotal + shipping + taxAmount;

    return OrderCostResult(
      baseUnitPrice: basePrice,
      basePriceUnit: basePriceUnit,
      baseQuantity: baseQty,
      baseCost: baseCost,
      serviceLines: lines,
      servicesTotal: servicesTotal,
      shipping: shipping,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      finalPerKg: conversion.totalKg > 0 ? grandTotal / conversion.totalKg : null,
      finalPerMetre:
          conversion.totalMetres > 0 ? grandTotal / conversion.totalMetres : null,
      finalPerPiece:
          conversion.totalPieces > 0 ? grandTotal / conversion.totalPieces : null,
    );
  }

  static ProductConversionResult convert({
    required String productId,
    required Map<String, double> fields,
    required double density,
    required String inputUnit,
    required double inputValue,
    double? cutLengthMm,
    double? cutWidthMm,
    double? overrideKgPerMetre,
    double? overrideKgPerPiece,
    double? overrideAreaPerPiece,
  }) {
    final spec = converterProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw const FormatException('کالای انتخابی معتبر نیست.'),
    );
    if (!spec.supportedUnits.contains(inputUnit)) {
      throw const FormatException('واحد ورودی برای این کالا مجاز نیست.');
    }
    if (!inputValue.isFinite || inputValue <= 0) {
      throw const FormatException('مقدار ورودی باید بزرگ‌تر از صفر باشد.');
    }
    if (spec.usesDensity && (!density.isFinite || density <= 0)) {
      throw const FormatException('چگالی جنس باید مثبت باشد.');
    }
    final useOverride = (overrideKgPerMetre != null && overrideKgPerMetre > 0) ||
        (overrideKgPerPiece != null && overrideKgPerPiece > 0);
    if (!useOverride) {
      for (final f in spec.fields) {
        final v = fields[f.key];
        if (v == null || !v.isFinite || (f.allowZero ? v < 0 : v <= 0)) {
          throw FormatException('${f.label}: مقدار معتبر وارد کنید.');
        }
        if (f.integerOnly && v != v.roundToDouble()) {
          throw FormatException('${f.label}: باید عدد صحیح باشد.');
        }
      }
    } else {
      final pb = fields['piecesPerBundle'];
      if (pb == null || !pb.isFinite || pb <= 0) {
        throw const FormatException('تعداد در بسته/بندیل باید بزرگ‌تر از صفر باشد.');
      }
      if (spec.hasMetres) {
        final pl = fields['pieceLengthM'];
        if (pl == null || !pl.isFinite || pl <= 0) {
          throw const FormatException('طول هر شاخه/برگ باید بزرگ‌تر از صفر باشد.');
        }
      }
    }

    double f(String k) => fields[k] ?? 0;
    final piecesPerBundle = f('piecesPerBundle');

    double kgPerMetre = 0;
    double areaPerMetre = 0;
    double pieceLengthM = 0;
    double kgPerPiece = 0;
    double areaPerPiece = 0;

    if (spec.hasMetres) {
      pieceLengthM = f('pieceLengthM');
      if (useOverride) {
        if (overrideKgPerMetre != null && overrideKgPerMetre > 0) {
          kgPerMetre = overrideKgPerMetre;
          kgPerPiece = kgPerMetre * pieceLengthM;
        } else {
          kgPerPiece = overrideKgPerPiece!;
          kgPerMetre = kgPerPiece / pieceLengthM;
        }
        if (overrideAreaPerPiece != null && overrideAreaPerPiece > 0) {
          areaPerPiece = overrideAreaPerPiece;
          areaPerMetre = areaPerPiece / pieceLengthM;
        }
      } else {
        double areaMm2 = 0;
        switch (productId) {
          case 'plate':
          case 'gutter': {
            final t = f('thicknessMm');
            final w = f('widthMm');
            final coat = f('coatGsm');
            areaMm2 = t * w;
            areaPerMetre = w / 1000.0;
            kgPerMetre = areaMm2 * density / 1e6 + areaPerMetre * (coat / 1000.0);
            break;
          }
          case 'wallpost': {
            final t = f('thicknessMm');
            final w = f('widthMm');
            areaMm2 = t * w;
            areaPerMetre = w / 1000.0;
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
          case 'rebar':
          case 'wire': {
            final d = f('diameterMm');
            areaMm2 = math.pi * d * d / 4.0;
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
          case 'ghameh': {
            final d = f('diameterMm');
            final acc = f('accessoriesKg');
            areaMm2 = math.pi * d * d / 4.0;
            final rawKgM = areaMm2 * density / 1e6;
            kgPerPiece = rawKgM * pieceLengthM + acc;
            kgPerMetre = kgPerPiece / pieceLengthM;
            break;
          }
          case 'rhs': {
            final h = f('heightMm');
            final b = f('widthMm');
            final t = f('thicknessMm');
            if (2 * t >= math.min(h, b)) {
              throw const FormatException('ضخامت قوطی باید کمتر از نصف کمترین ضلع باشد.');
            }
            areaMm2 = h * b - (h - 2 * t) * (b - 2 * t);
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
          case 'pipe': {
            final od = f('odMm');
            final t = f('thicknessMm');
            if (2 * t >= od) {
              throw const FormatException('دو برابر ضخامت باید کمتر از قطر خارجی باشد.');
            }
            areaMm2 = math.pi * t * (od - t);
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
          case 'flat': {
            final w = f('widthMm');
            final t = f('thicknessMm');
            areaMm2 = w * t;
            areaPerMetre = w / 1000.0;
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
          case 'angle': {
            final l1 = f('leg1Mm');
            final l2 = f('leg2Mm');
            final t = f('thicknessMm');
            if (t >= math.min(l1, l2)) {
              throw const FormatException('ضخامت باید کمتر از طول بال‌ها باشد.');
            }
            areaMm2 = t * (l1 + l2 - t);
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
          case 'channel':
          case 'ibeam_geom': {
            final h = f('heightMm');
            final b = f('widthMm');
            final tw = f('webMm');
            final tf = f('flangeMm');
            if (2 * tf >= h || tw >= b) {
              throw const FormatException('ابعاد جان و بال معتبر نیست.');
            }
            areaMm2 = 2 * b * tf + (h - 2 * tf) * tw;
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
          case 'beam':
          case 'hbeam':
          case 'catalog_kgm': {
            kgPerMetre = f('kgPerMetre');
            break;
          }
          case 'tee': {
            final h = f('heightMm');
            final b = f('widthMm');
            final tw = f('webMm');
            final tf = f('flangeMm');
            if (tf >= h || tw >= b) {
              throw const FormatException('ابعاد سپری معتبر نیست.');
            }
            areaMm2 = b * tf + (h - tf) * tw;
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
          case 'bar': {
            areaMm2 = f('heightMm') * f('widthMm');
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
          case 'hex': {
            final s = f('flatToFlatMm');
            areaMm2 = math.sqrt(3) / 2.0 * s * s;
            kgPerMetre = areaMm2 * density / 1e6;
            break;
          }
        }
        if (productId != 'ghameh') {
          kgPerPiece = kgPerMetre * pieceLengthM;
        }
        areaPerPiece = areaPerMetre * pieceLengthM;
      }
      final kgPerBundle = kgPerPiece * piecesPerBundle;

      double kgPerCut = 0;
      double areaPerCut = 0;
      double cutLenM = 0;
      bool hasValidCutSpec = false;

      if (spec.supportsCutCount) {
        final hasLen =
            cutLengthMm != null && cutLengthMm.isFinite && cutLengthMm > 0;
        final hasWid =
            cutWidthMm != null && cutWidthMm.isFinite && cutWidthMm > 0;
        if (inputUnit == 'cut') {
          if (!hasLen) {
            throw const FormatException(
                'طول هر عدد برش‌خورده (میلی‌متر) باید بزرگ‌تر از صفر باشد.');
          }
          if (productId == 'plate' && !hasWid) {
            throw const FormatException(
                'عرض هر عدد برش‌خورده (میلی‌متر) باید بزرگ‌تر از صفر باشد.');
          }
        }
        if (hasLen && (productId != 'plate' || hasWid)) {
          hasValidCutSpec = true;
          cutLenM = cutLengthMm / 1000.0;
          if (productId == 'plate') {
            final t = f('thicknessMm');
            final coat = f('coatGsm');
            areaPerCut = (cutWidthMm! / 1000.0) * cutLenM;
            kgPerCut = (t * cutWidthMm * cutLengthMm * density / 1e9) +
                areaPerCut * (coat / 1000.0);
          } else {
            kgPerCut = kgPerMetre * cutLenM;
            areaPerCut = areaPerMetre * cutLenM;
          }
        }
      }

      late final double totalMetres;
      late final double totalKg;
      late final double totalAreaM2;
      late final double totalCuts;
      switch (inputUnit) {
        case 'm':
          totalMetres = inputValue;
          totalKg = totalMetres * kgPerMetre;
          totalAreaM2 = totalMetres * areaPerMetre;
          totalCuts = hasValidCutSpec && kgPerCut > 0 ? totalKg / kgPerCut : 0;
          break;
        case 'm2':
          totalMetres = inputValue / areaPerMetre;
          totalKg = totalMetres * kgPerMetre;
          totalAreaM2 = inputValue;
          totalCuts = hasValidCutSpec && kgPerCut > 0 ? totalKg / kgPerCut : 0;
          break;
        case 'kg':
          totalKg = inputValue;
          totalMetres = totalKg / kgPerMetre;
          totalAreaM2 = totalMetres * areaPerMetre;
          totalCuts = hasValidCutSpec && kgPerCut > 0 ? totalKg / kgPerCut : 0;
          break;
        case 'ton':
          totalKg = inputValue * 1000.0;
          totalMetres = totalKg / kgPerMetre;
          totalAreaM2 = totalMetres * areaPerMetre;
          totalCuts = hasValidCutSpec && kgPerCut > 0 ? totalKg / kgPerCut : 0;
          break;
        case 'piece':
          totalMetres = inputValue * pieceLengthM;
          totalKg = totalMetres * kgPerMetre;
          totalAreaM2 = totalMetres * areaPerMetre;
          totalCuts = hasValidCutSpec && kgPerCut > 0 ? totalKg / kgPerCut : 0;
          break;
        case 'bundle':
          totalMetres = inputValue * piecesPerBundle * pieceLengthM;
          totalKg = totalMetres * kgPerMetre;
          totalAreaM2 = totalMetres * areaPerMetre;
          totalCuts = hasValidCutSpec && kgPerCut > 0 ? totalKg / kgPerCut : 0;
          break;
        case 'cut':
          totalCuts = inputValue;
          totalKg = totalCuts * kgPerCut;
          totalAreaM2 = totalCuts * areaPerCut;
          totalMetres = productId == 'plate'
              ? (areaPerMetre > 0 ? totalAreaM2 / areaPerMetre : 0)
              : totalCuts * cutLenM;
          break;
        default:
          throw const FormatException('واحد ورودی برای این کالا مجاز نیست.');
      }

      final totalPieces = totalKg / kgPerPiece;
      final totalBundles = totalPieces / piecesPerBundle;

      CutAllocationResult? cutAlloc;
      if (hasValidCutSpec && totalCuts > 0) {
        if (productId == 'plate') {
          final stockW = f('widthMm');
          final stockL = pieceLengthM * 1000.0;
          final fitNormal = (stockW ~/ cutWidthMm!) * (stockL ~/ cutLengthMm!);
          final fitRotated = (stockW ~/ cutLengthMm) * (stockL ~/ cutWidthMm);
          final cutsPerStock = math.max(fitNormal, fitRotated);
          final fits = cutsPerStock > 0;
          final requiredStock =
              fits ? (totalCuts / cutsPerStock).ceil() : 0;
          final stockTotalKg = requiredStock * kgPerPiece;
          final wasteKg = fits ? math.max(0.0, stockTotalKg - totalKg) : 0.0;
          final wasteArea = fits
              ? math.max(0.0, requiredStock * areaPerPiece - totalAreaM2)
              : 0.0;
          final wastePct =
              stockTotalKg > 0 ? (wasteKg / stockTotalKg) * 100.0 : 0.0;
          cutAlloc = CutAllocationResult(
            isSheet: true,
            fitsInStock: fits,
            cutsPerStockPiece: cutsPerStock,
            requiredStockPieces: requiredStock,
            kgPerCut: kgPerCut,
            areaPerCutM2: areaPerCut,
            cutLengthM: cutLenM,
            cutWidthMm: cutWidthMm,
            totalCuts: totalCuts,
            stockPieceKg: kgPerPiece,
            stockTotalKg: stockTotalKg,
            wasteKg: wasteKg,
            wasteLengthM: 0,
            wasteAreaM2: wasteArea,
            wastePercent: wastePct,
          );
        } else {
          final cutsPerStock = (pieceLengthM + 1e-9) ~/ cutLenM;
          final fits = cutsPerStock > 0;
          final requiredStock =
              fits ? (totalCuts / cutsPerStock).ceil() : 0;
          final stockTotalKg = requiredStock * kgPerPiece;
          final wasteKg = fits ? math.max(0.0, stockTotalKg - totalKg) : 0.0;
          final wasteLength = fits
              ? math.max(0.0, requiredStock * pieceLengthM - totalCuts * cutLenM)
              : 0.0;
          final wastePct =
              stockTotalKg > 0 ? (wasteKg / stockTotalKg) * 100.0 : 0.0;
          cutAlloc = CutAllocationResult(
            isSheet: false,
            fitsInStock: fits,
            cutsPerStockPiece: cutsPerStock,
            requiredStockPieces: requiredStock,
            kgPerCut: kgPerCut,
            areaPerCutM2: areaPerCut,
            cutLengthM: cutLenM,
            cutWidthMm: 0,
            totalCuts: totalCuts,
            stockPieceKg: kgPerPiece,
            stockTotalKg: stockTotalKg,
            wasteKg: wasteKg,
            wasteLengthM: wasteLength,
            wasteAreaM2: 0,
            wastePercent: wastePct,
          );
        }
      }

      return ProductConversionResult(
        spec: spec,
        density: density,
        kgPerMetre: kgPerMetre,
        kgPerPiece: kgPerPiece,
        kgPerBundle: kgPerBundle,
        areaPerPiece: areaPerPiece,
        piecesPerBundle: piecesPerBundle,
        pieceLengthM: pieceLengthM,
        totalKg: totalKg,
        totalTon: totalKg / 1000.0,
        totalMetres: totalMetres,
        totalAreaM2: totalAreaM2,
        totalPieces: totalPieces,
        totalBundles: totalBundles,
        kgPerCut: kgPerCut,
        totalCuts: totalCuts,
        cutAllocation: cutAlloc,
      );
    } else {
      // Discrete surface/piece products (mesh, mesh_area, cut_plate, stud, unit_item, rabitz/turi)
      if (useOverride && overrideKgPerPiece != null && overrideKgPerPiece > 0) {
        kgPerPiece = overrideKgPerPiece;
        if (overrideAreaPerPiece != null && overrideAreaPerPiece > 0) {
          areaPerPiece = overrideAreaPerPiece;
        } else if (productId == 'cut_plate') {
          areaPerPiece = (f('widthMm') / 1000.0) * (f('lengthMm') / 1000.0);
        } else if (productId == 'mesh_area' || productId == 'piece_pack') {
          areaPerPiece = f('areaPerPieceM2');
        } else if (productId == 'mesh') {
          areaPerPiece = f('panelWidthM') * f('panelLengthM');
        } else {
          areaPerPiece = 0;
        }
      } else if (productId == 'mesh') {
        final pw = f('panelWidthM');
        final pl = f('panelLengthM');
        final dx = f('dxMm');
        final dy = f('dyMm');
        final nx = f('nx');
        final ny = f('ny');
        areaPerPiece = pw * pl;
        kgPerPiece =
            (nx * pl * math.pi * dx * dx / 4.0 + ny * pw * math.pi * dy * dy / 4.0) *
                density /
                1e6;
      } else if (productId == 'mesh_area') {
        areaPerPiece = f('areaPerPieceM2');
        final kgPerM2 = (overrideKgPerMetre != null && overrideKgPerMetre > 0)
            ? overrideKgPerMetre
            : f('kgPerM2');
        kgPerPiece = kgPerM2 * areaPerPiece;
      } else if (productId == 'stud') {
        final d = f('diameterMm');
        final l = f('lengthMm');
        if (l <= d * 0.6) {
          throw const FormatException('طول گل‌میخ باید بیشتر از ضخامت سر آن باشد.');
        }
        final shankLen = l - 0.52 * d;
        final headDia = 1.67 * d;
        final headH = 0.52 * d;
        final volMm3 = math.pi * (d / 2.0) * (d / 2.0) * shankLen +
            math.pi * (headDia / 2.0) * (headDia / 2.0) * headH;
        kgPerPiece = volMm3 * density / 1e9;
        areaPerPiece = 0;
      } else if (productId == 'cut_plate') {
        final t = f('thicknessMm');
        final w = f('widthMm');
        final l = f('lengthMm');
        areaPerPiece = (w / 1000.0) * (l / 1000.0);
        kgPerPiece = t * w * l * density / 1e9;
      } else if (productId == 'unit_item') {
        kgPerPiece = f('kgPerPiece');
        areaPerPiece = 0;
      } else {
        kgPerPiece = f('kgPerPiece');
        areaPerPiece = f('areaPerPieceM2');
      }
      final kgPerBundle = kgPerPiece * piecesPerBundle;

      late final double totalPieces;
      switch (inputUnit) {
        case 'kg':
          totalPieces = inputValue / kgPerPiece;
          break;
        case 'ton':
          totalPieces = (inputValue * 1000.0) / kgPerPiece;
          break;
        case 'm2':
          totalPieces = inputValue / areaPerPiece;
          break;
        case 'piece':
          totalPieces = inputValue;
          break;
        case 'bundle':
          totalPieces = inputValue * piecesPerBundle;
          break;
        default:
          throw const FormatException('واحد ورودی برای این کالا مجاز نیست.');
      }

      final totalKg = totalPieces * kgPerPiece;
      return ProductConversionResult(
        spec: spec,
        density: density,
        kgPerMetre: 0,
        kgPerPiece: kgPerPiece,
        kgPerBundle: kgPerBundle,
        areaPerPiece: areaPerPiece,
        piecesPerBundle: piecesPerBundle,
        pieceLengthM: 0,
        totalKg: totalKg,
        totalTon: totalKg / 1000.0,
        totalMetres: 0,
        totalAreaM2: totalPieces * areaPerPiece,
        totalPieces: totalPieces,
        totalBundles: totalPieces / piecesPerBundle,
      );
    }
  }

  /// Isolated calculation for cut-to-size orders (قطعه برش‌خورده):
  /// Stock sheet/branch dimensions (widthMm for plate, pieceLengthM, piecesPerBundle)
  /// have ZERO effect unless [includeStockWaste] is explicitly enabled.
  static ProductConversionResult convertCutPiece({
    required String productId,
    required Map<String, double> fields,
    required double density,
    required String inputUnit, // 'cut', 'kg', 'ton', 'm', 'm2'
    required double inputValue,
    required double cutLengthMm,
    double? cutWidthMm,
    double? overrideKgPerMetre,
    bool includeStockWaste = false,
    double? stockWidthMm,
    double? stockLengthM,
  }) {
    final spec = converterProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw const FormatException('کالای انتخابی معتبر نیست.'),
    );
    if (!spec.supportsCutCount) {
      throw const FormatException('این کالا در حالت برش‌خورده پشتیبانی نمی‌شود.');
    }
    if (!inputValue.isFinite || inputValue <= 0) {
      throw const FormatException('مقدار سفارش باید بزرگ‌تر از صفر باشد.');
    }
    if (!cutLengthMm.isFinite || cutLengthMm <= 0) {
      throw const FormatException(
          'طول قطعه برش‌خورده (میلی‌متر) باید بزرگ‌تر از صفر باشد.');
    }
    if (productId == 'plate' &&
        (cutWidthMm == null || !cutWidthMm.isFinite || cutWidthMm <= 0)) {
      throw const FormatException(
          'عرض قطعه برش‌خورده (میلی‌متر) باید بزرگ‌تر از صفر باشد.');
    }
    if (spec.usesDensity && (!density.isFinite || density <= 0)) {
      throw const FormatException('چگالی جنس باید مثبت باشد.');
    }

    double f(String k) {
      final v = fields[k];
      final meta = spec.fields.firstWhere(
        (x) => x.key == k,
        orElse: () => const ConverterField('', '', 0),
      );
      if (v == null || !v.isFinite || (meta.allowZero ? v < 0 : v <= 0)) {
        throw FormatException(
            '${meta.label.isEmpty ? k : meta.label}: مقدار معتبر وارد کنید.');
      }
      return v;
    }

    final cutLenM = cutLengthMm / 1000.0;
    double kgPerMetre = 0;
    double areaPerMetre = 0;
    double kgPerCut = 0;
    double areaPerCut = 0;

    final usePresetKgm = overrideKgPerMetre != null && overrideKgPerMetre > 0;
    if (productId == 'plate') {
      final t = f('thicknessMm');
      final coat = f('coatGsm');
      final wCutM = cutWidthMm! / 1000.0;
      areaPerCut = wCutM * cutLenM;
      kgPerCut = (t * cutWidthMm * cutLengthMm * density / 1e9) +
          areaPerCut * (coat / 1000.0);
      areaPerMetre = wCutM;
      kgPerMetre = areaPerCut > 0 ? kgPerCut / cutLenM : 0;
    } else if (usePresetKgm) {
      kgPerMetre = overrideKgPerMetre;
      kgPerCut = kgPerMetre * cutLenM;
    } else {
      double areaMm2 = 0;
      switch (productId) {
        case 'gutter':
          final t = f('thicknessMm');
          final w = f('widthMm');
          final coat = f('coatGsm');
          areaMm2 = t * w;
          areaPerMetre = w / 1000.0;
          kgPerMetre =
              areaMm2 * density / 1e6 + areaPerMetre * (coat / 1000.0);
          break;
        case 'wallpost':
          final t = f('thicknessMm');
          final w = f('widthMm');
          areaMm2 = t * w;
          areaPerMetre = w / 1000.0;
          kgPerMetre = areaMm2 * density / 1e6;
          break;
        case 'rebar':
        case 'wire':
        case 'ghameh':
          final d = f('diameterMm');
          areaMm2 = math.pi * d * d / 4.0;
          kgPerMetre = areaMm2 * density / 1e6;
          break;
        case 'rhs':
          final h = f('heightMm');
          final b = f('widthMm');
          final t = f('thicknessMm');
          if (2 * t >= math.min(h, b)) {
            throw const FormatException(
                'ضخامت قوطی باید کمتر از نصف کمترین ضلع باشد.');
          }
          areaMm2 = h * b - (h - 2 * t) * (b - 2 * t);
          kgPerMetre = areaMm2 * density / 1e6;
          break;
        case 'pipe':
          final od = f('odMm');
          final t = f('thicknessMm');
          if (2 * t >= od) {
            throw const FormatException(
                'دو برابر ضخامت باید کمتر از قطر خارجی باشد.');
          }
          areaMm2 = math.pi * t * (od - t);
          kgPerMetre = areaMm2 * density / 1e6;
          break;
        case 'flat':
          final w = f('widthMm');
          final t = f('thicknessMm');
          areaMm2 = w * t;
          areaPerMetre = w / 1000.0;
          kgPerMetre = areaMm2 * density / 1e6;
          break;
        case 'angle':
          final l1 = f('leg1Mm');
          final l2 = f('leg2Mm');
          final t = f('thicknessMm');
          if (t >= math.min(l1, l2)) {
            throw const FormatException('ضخامت باید کمتر از طول بال‌ها باشد.');
          }
          areaMm2 = t * (l1 + l2 - t);
          kgPerMetre = areaMm2 * density / 1e6;
          break;
        case 'channel':
        case 'ibeam_geom':
          final h = f('heightMm');
          final b = f('widthMm');
          final tw = f('webMm');
          final tf = f('flangeMm');
          if (2 * tf >= h || tw >= b) {
            throw const FormatException('ابعاد جان و بال معتبر نیست.');
          }
          areaMm2 = 2 * b * tf + (h - 2 * tf) * tw;
          kgPerMetre = areaMm2 * density / 1e6;
          break;
        case 'beam':
        case 'hbeam':
        case 'catalog_kgm':
          kgPerMetre = f('kgPerMetre');
          break;
        case 'tee':
          final h = f('heightMm');
          final b = f('widthMm');
          final tw = f('webMm');
          final tf = f('flangeMm');
          if (tf >= h || tw >= b) {
            throw const FormatException('ابعاد سپری معتبر نیست.');
          }
          areaMm2 = b * tf + (h - tf) * tw;
          kgPerMetre = areaMm2 * density / 1e6;
          break;
        case 'bar':
          areaMm2 = f('heightMm') * f('widthMm');
          kgPerMetre = areaMm2 * density / 1e6;
          break;
        case 'hex':
          final s = f('flatToFlatMm');
          areaMm2 = math.sqrt(3) / 2.0 * s * s;
          kgPerMetre = areaMm2 * density / 1e6;
          break;
      }
      if (productId == 'ghameh') {
        final acc = f('accessoriesKg');
        kgPerCut = kgPerMetre * cutLenM + acc;
      } else {
        kgPerCut = kgPerMetre * cutLenM;
      }
      areaPerCut = areaPerMetre * cutLenM;
    }

    late final double totalCuts;
    late final double totalKg;
    late final double totalAreaM2;
    late final double totalMetres;

    switch (inputUnit) {
      case 'cut':
        totalCuts = inputValue;
        totalKg = totalCuts * kgPerCut;
        totalAreaM2 = totalCuts * areaPerCut;
        totalMetres = totalCuts * cutLenM;
        break;
      case 'kg':
        totalKg = inputValue;
        totalCuts = totalKg / kgPerCut;
        totalAreaM2 = totalCuts * areaPerCut;
        totalMetres = totalCuts * cutLenM;
        break;
      case 'ton':
        totalKg = inputValue * 1000.0;
        totalCuts = totalKg / kgPerCut;
        totalAreaM2 = totalCuts * areaPerCut;
        totalMetres = totalCuts * cutLenM;
        break;
      case 'm':
        totalMetres = inputValue;
        totalCuts = totalMetres / cutLenM;
        totalKg = totalCuts * kgPerCut;
        totalAreaM2 = totalCuts * areaPerCut;
        break;
      case 'm2':
        if (areaPerCut <= 0) {
          throw const FormatException('این کالا واحد مترمربع ندارد.');
        }
        totalAreaM2 = inputValue;
        totalCuts = totalAreaM2 / areaPerCut;
        totalKg = totalCuts * kgPerCut;
        totalMetres = totalCuts * cutLenM;
        break;
      default:
        throw const FormatException('واحد انتخابی در حالت برش‌خورده مجاز نیست.');
    }

    CutAllocationResult? cutAlloc;
    double stockPieceKg = kgPerCut;
    double stockPieceArea = areaPerCut;
    double stockLenM = cutLenM;

    if (includeStockWaste) {
      if (stockLengthM == null || !stockLengthM.isFinite || stockLengthM <= 0) {
        throw const FormatException(
            'طول شیت/شاخه فابریک (متر) باید بزرگ‌تر از صفر باشد.');
      }
      stockLenM = stockLengthM;
      if (productId == 'plate') {
        if (stockWidthMm == null ||
            !stockWidthMm.isFinite ||
            stockWidthMm <= 0) {
          throw const FormatException(
              'عرض ورق فابریک (میلی‌متر) باید بزرگ‌تر از صفر باشد.');
        }
        final t = f('thicknessMm');
        final coat = f('coatGsm');
        final stockLmm = stockLengthM * 1000.0;
        stockPieceArea = (stockWidthMm / 1000.0) * stockLengthM;
        stockPieceKg = (t * stockWidthMm * stockLmm * density / 1e9) +
            stockPieceArea * (coat / 1000.0);
        final fitNormal =
            (stockWidthMm ~/ cutWidthMm!) * (stockLmm ~/ cutLengthMm);
        final fitRotated =
            (stockWidthMm ~/ cutLengthMm) * (stockLmm ~/ cutWidthMm);
        final cutsPerStock = math.max(fitNormal, fitRotated);
        final fits = cutsPerStock > 0;
        final requiredStock = fits ? (totalCuts / cutsPerStock).ceil() : 0;
        final stockTotalKg = requiredStock * stockPieceKg;
        final wasteKg = fits ? math.max(0.0, stockTotalKg - totalKg) : 0.0;
        final wasteArea = fits
            ? math.max(0.0, requiredStock * stockPieceArea - totalAreaM2)
            : 0.0;
        final wastePct =
            stockTotalKg > 0 ? (wasteKg / stockTotalKg) * 100.0 : 0.0;
        cutAlloc = CutAllocationResult(
          isSheet: true,
          fitsInStock: fits,
          cutsPerStockPiece: cutsPerStock,
          requiredStockPieces: requiredStock,
          kgPerCut: kgPerCut,
          areaPerCutM2: areaPerCut,
          cutLengthM: cutLenM,
          cutWidthMm: cutWidthMm,
          totalCuts: totalCuts,
          stockPieceKg: stockPieceKg,
          stockTotalKg: stockTotalKg,
          wasteKg: wasteKg,
          wasteLengthM: 0,
          wasteAreaM2: wasteArea,
          wastePercent: wastePct,
        );
      } else {
        stockPieceKg = kgPerMetre * stockLengthM;
        stockPieceArea = areaPerMetre * stockLengthM;
        final cutsPerStock = (stockLengthM + 1e-9) ~/ cutLenM;
        final fits = cutsPerStock > 0;
        final requiredStock = fits ? (totalCuts / cutsPerStock).ceil() : 0;
        final stockTotalKg = requiredStock * stockPieceKg;
        final wasteKg = fits ? math.max(0.0, stockTotalKg - totalKg) : 0.0;
        final wasteLength = fits
            ? math.max(0.0, requiredStock * stockLengthM - totalCuts * cutLenM)
            : 0.0;
        final wastePct =
            stockTotalKg > 0 ? (wasteKg / stockTotalKg) * 100.0 : 0.0;
        cutAlloc = CutAllocationResult(
          isSheet: false,
          fitsInStock: fits,
          cutsPerStockPiece: cutsPerStock,
          requiredStockPieces: requiredStock,
          kgPerCut: kgPerCut,
          areaPerCutM2: areaPerCut,
          cutLengthM: cutLenM,
          cutWidthMm: 0,
          totalCuts: totalCuts,
          stockPieceKg: stockPieceKg,
          stockTotalKg: stockTotalKg,
          wasteKg: wasteKg,
          wasteLengthM: wasteLength,
          wasteAreaM2: 0,
          wastePercent: wastePct,
        );
      }
    }

    return ProductConversionResult(
      spec: spec,
      density: density,
      kgPerMetre: kgPerMetre,
      kgPerPiece: stockPieceKg,
      kgPerBundle: stockPieceKg,
      areaPerPiece: stockPieceArea,
      piecesPerBundle: 1,
      pieceLengthM: stockLenM,
      totalKg: totalKg,
      totalTon: totalKg / 1000.0,
      totalMetres: totalMetres,
      totalAreaM2: totalAreaM2,
      totalPieces: cutAlloc != null ? cutAlloc.requiredStockPieces.toDouble() : totalCuts,
      totalBundles: 1,
      kgPerCut: kgPerCut,
      totalCuts: totalCuts,
      cutAllocation: cutAlloc,
    );
  }
}
