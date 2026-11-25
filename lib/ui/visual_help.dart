import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';

/// A compact circular `!` icon button that opens an illustrated visual guide
/// for any metric, field, section, or filter across all tabs without cluttering
/// the layout.
class HelpBadge extends StatelessWidget {
  final String topic;
  final String? titleOverride;
  final double size;

  const HelpBadge({
    super.key,
    required this.topic,
    this.titleOverride,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'راهنمای تصویری این معیار',
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showVisualHelp(context, topic, titleOverride: titleOverride),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: teal.withOpacity(.12),
                border: Border.all(color: teal.withOpacity(.55), width: 1.2),
              ),
              child: Text(
                '!',
                style: TextStyle(
                  color: teal,
                  fontSize: size * 0.68,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
}

class _HelpSpec {
  final String title;
  final String subtitle;
  final String formulaOrRule;
  final String example;
  final _DiagramKind diagram;

  const _HelpSpec({
    required this.title,
    required this.subtitle,
    required this.formulaOrRule,
    required this.example,
    required this.diagram,
  });
}

enum _DiagramKind {
  plate,
  cutPlate,
  rebar,
  rhs,
  pipe,
  angle,
  channel,
  beam,
  hbeam,
  tee,
  flat,
  bar,
  hex,
  stud,
  wallpost,
  gutter,
  ghameh,
  mesh,
  unitItem,
  lightHeavy,
  orderQty,
  cutPiece,
  bundle,
  services,
  density,
  window,
  tax,
  basis,
  sort,
  specFilter,
  rangeStats,
  chartMode,
  cityScope,
  sources,
}

const _helpSpecs = <String, _HelpSpec>{
  'plate': _HelpSpec(
    title: 'ورق تخت (سیاه، روغنی، گالوانیزه)',
    subtitle: 'وزن از ضربِ ضخامت پایه، عرض، طول و چگالی جنس به دست می‌آید.',
    formulaOrRule: 'وزن = طول (متر) × عرض (متر) × ضخامت (میل) × ۷٫۸۵ (+ جرم پوشش دو رو)',
    example: 'مثال: ورق ۲ میل به ابعاد ۱×۲ متر ➔ ۲ × ۱ × ۲ × ۷٫۸۵ = ۳۱٫۴ کیلوگرم',
    diagram: _DiagramKind.plate,
  ),
  'cut_plate': _HelpSpec(
    title: 'صفحه ستون، پلیت و قطعه برشی',
    subtitle: 'پلیت با طول، عرض و ضخامت مشخص (به سانتی‌متر یا میلی‌متر) بر مبنای هر عدد محاسبه می‌شود.',
    formulaOrRule: 'وزن هر عدد = عرض (متر) × طول (متر) × ضخامت (میل) × چگالی',
    example: 'مثال: پلیت ۸ میل ۲۰×۲۰ سانتی‌متر ➔ ۰٫۲ × ۰٫۲ × ۸ × ۷٫۸۵ = ۲٫۵۱۲ کیلوگرم',
    diagram: _DiagramKind.cutPlate,
  ),
  'rebar': _HelpSpec(
    title: 'میلگرد (ساده، آجدار، مفتول)',
    subtitle: 'سایز میلگرد همان قطر اسمی بدنه بر حسب میلی‌متر است (مثل ۱۴، ۱۶، ۱۸).',
    formulaOrRule: 'وزن هر متر ≈ (قطر × قطر ÷ ۱۶۲) کیلوگرم • شاخه استاندارد معمولاً ۱۲ متر',
    example: 'مثال: میلگرد ۱۶ دوازده‌متری ≈ ۱۹ کیلوگرم در هر شاخه',
    diagram: _DiagramKind.rebar,
  ),
  'wire': _HelpSpec(
    title: 'مفتول / سیم کلافی',
    subtitle: 'قطر سیم به میلی‌متر و متراژ یک کلاف یا حلقه مبنای تبدیل به وزن و تعداد کلاف است.',
    formulaOrRule: 'وزن ۱ متر = سطح مقطع دایره × چگالی',
    example: 'مثال: مفتول ۲٫۵ میل، کلاف ۱۰۰ متری ≈ ۳٫۸۵ کیلوگرم',
    diagram: _DiagramKind.rebar,
  ),
  'rhs': _HelpSpec(
    title: 'قوطی و پروفیل (مربع / مستطیل)',
    subtitle: 'ابعاد بیرونی (ارتفاع × عرض) به میلی‌متر و ضخامت دیواره به میلی‌متر وزن هر شاخه ۶ متری را می‌سازد.',
    formulaOrRule: 'تفاوت قوطی سبک و سنگین با ابعاد ظاهری برابر، به ضخامت ورق جداره برمی‌گردد.',
    example: 'مثال: قوطی ۴۰×۴۰ سبک (≈۱٫۵ میل) ۱۴ کگ و سنگین (۲ میل) ۱۷٫۱ کگ در ۶ متر',
    diagram: _DiagramKind.rhs,
  ),
  'pipe': _HelpSpec(
    title: 'لوله (سیاه، گازی، داربستی، صنعتی)',
    subtitle: 'محاسبه دقیق با قطر بیرونی واقعی (OD) و ضخامت جداره انجام می‌شود؛ نمره اینچی به‌تنهایی قطر بیرونی نیست.',
    formulaOrRule: 'در لوله‌های بازاری هم‌سایز، سبک (ضخامت ۲ میل) و سنگین (ضخامت ۲٫۵ میل) هستند.',
    example: 'مثال: لوله ۳ بازاری ۶متری با ضخامت ۲ = ۹٫۵ کگ و با ضخامت ۲٫۵ = ۱۱ کگ',
    diagram: _DiagramKind.pipe,
  ),
  'angle': _HelpSpec(
    title: 'نبشی (بال مساوی و نامساوی)',
    subtitle: 'نبشی با اندازه هر دو بال و ضخامت بال (میلی‌متر) سنجیده می‌شود؛ نبشی ۸ یعنی ۸۰×۸۰ میل.',
    formulaOrRule: 'نبشی ۸ در ۸ بازاری (شاخه ۶ متری) حدود ۵۸ کیلوگرم (۹٫۷ کگ/متر) است.',
    example: 'برای نبشی بال نامساوی یا ضخامت خاص از حالت «ابعاد دستی» استفاده کنید.',
    diagram: _DiagramKind.angle,
  ),
  'channel': _HelpSpec(
    title: 'ناودانی (روس / اروپا UPN / پرسی)',
    subtitle: 'سایز ناودانی همان ارتفاع جان به سانتی‌متر است (ناودانی ۱۰ یعنی ارتفاع ۱۰۰ میلی‌متر).',
    formulaOrRule: 'مدل «سبک (روس)» ضخامت کمتر و مدل «سنگین (اروپا UPN)» وزن کامل اشتال دارد.',
    example: 'ناودانی پرسی مثل ۱۰ در ۲۵ (۵ میل) را در حالت ابعاد دستی وارد کنید.',
    diagram: _DiagramKind.channel,
  ),
  'beam': _HelpSpec(
    title: 'تیرآهن IPE (بال نیم‌پهن)',
    subtitle: 'تیرآهن با شماره ارتفاع جان (۸ تا ۴۰ سانتی‌متر) شناخته می‌شود؛ طول استاندارد ۱۲ متر است.',
    formulaOrRule: 'تیرآهن سبک (متفرقه) کمی کمتر از جدول اشتال (ذوب‌آهن) وزن دارد.',
    example: 'مثال: تیرآهن ۱۶ استاندارد در شاخه ۱۲ متری ≈ ۱۹۲ کیلوگرم',
    diagram: _DiagramKind.beam,
  ),
  'ibeam_geom': _HelpSpec(
    title: 'تیرآهن I / H با ابعاد دستی',
    subtitle: 'ارتفاع کل (H)، عرض بال (B)، ضخامت جان (tw) و ضخامت بال (tf) به میلی‌متر.',
    formulaOrRule: 'برای محاسبه مقاطع سفارشی یا تیرورق به‌کار می‌رود.',
    example: 'ورود ابعاد بر حسب میلی‌متر',
    diagram: _DiagramKind.beam,
  ),
  'hbeam': _HelpSpec(
    title: 'تیرآهن هاش ستونی (HEA سبک / HEB سنگین)',
    subtitle: 'تیرآهن بال‌پهن با دو رده اصلی سبک (HEA) و سنگین (HEB) عرضه می‌شود.',
    formulaOrRule: 'هاش هم‌سایز در مدل HEB بال و جان ضخیم‌تری نسبت به HEA دارد.',
    example: 'مثال: هاش ۲۰ سبک = ۵۰۸ کیلوگرم، سنگین = ۷۳۶ کیلوگرم در ۱۲ متر',
    diagram: _DiagramKind.hbeam,
  ),
  'catalog_kgm': _HelpSpec(
    title: 'مقطع بر مبنای وزن هر متر جدول/باسکول',
    subtitle: 'هر زمان وزن دقیق یک متر از فاکتور یا کاتالوگ سازنده را دارید، دقیق‌ترین مبنا همین گزینه است.',
    formulaOrRule: 'وزن کل = وزن هر متر × متراژ',
    example: 'مناسب مقاطع Z، C، ریل، تیرآهن و شاخه‌های غیرفابریک',
    diagram: _DiagramKind.beam,
  ),
  'tee': _HelpSpec(
    title: 'سپری (T شکل)',
    subtitle: 'سایز سپری به سانتی‌متر (مثلاً سپری ۳، ۴، ۵) یا با ابعاد دقیق بال و جان.',
    formulaOrRule: 'شاخه استاندارد سپری معمولاً ۶ متری است.',
    example: 'مثال: سپری ۴ شش‌متری حدود ۱۷٫۸ کیلوگرم وزن دارد.',
    diagram: _DiagramKind.tee,
  ),
  'flat': _HelpSpec(
    title: 'تسمه (فولادی، استیل، مس)',
    subtitle: 'تسمه بر اساس عرض و ضخامت به میلی‌متر (یا سانتی‌متر) و طول شاخه سنجیده می‌شود.',
    formulaOrRule: 'وزن هر متر = عرض (میل) × ضخامت (میل) × چگالی ÷ ۱٬۰۰۰٬۰۰۰',
    example: 'مثال: تسمه ۵۰×۵ (عرض ۵ سانت، ض ۵ میل) = ۱٫۹۶ کیلوگرم در هر متر',
    diagram: _DiagramKind.flat,
  ),
  'bar': _HelpSpec(
    title: 'چهارپهلو / شمش توپر',
    subtitle: 'مقطع مستطیلی یا مربعی کاملاً توپر (توخالی نیست) با ارتفاع و عرض به میلی‌متر.',
    formulaOrRule: 'وزن هر متر = ارتفاع × عرض × چگالی ÷ ۱٬۰۰۰٬۰۰۰',
    example: 'مثال: چهارپهلو ۴۰×۴۰ = ۱۲٫۵۶ کیلوگرم در هر متر',
    diagram: _DiagramKind.bar,
  ),
  'hex': _HelpSpec(
    title: 'شش‌پر توپر (آچارخور)',
    subtitle: 'اندازه ورودی «فاصله دو وجه موازی» (آچارخور) است؛ نه فاصله دو رأس روبه‌رو.',
    formulaOrRule: 'سطح مقطع = (√۳ ÷ ۲) × S²',
    example: 'مثال: شش‌پر ۳۰ (فاصله دو وجه ۳۰ میل) ≈ ۶٫۱۲ کگ/متر',
    diagram: _DiagramKind.hex,
  ),
  'stud': _HelpSpec(
    title: 'گل‌میخ (برشگیر سقف عرشه فولادی)',
    subtitle: 'میله فولادی سرپهن برای انتقال برش بین ورق عرشه و بتن. با قطر (d) و طول (L) سنجیده می‌شود.',
    formulaOrRule: 'علت بی‌عددی برخی فروشندگان: سایز ۱۹×۱۰۰ میلی‌متر (~۲۶۲ گرم) سایز پیش‌فرض بازار است.',
    example: 'قطرهای رایج: ۱۳، ۱۶، ۱۹، ۲۲، ۲۵ میل و طول ۵۰ تا ۲۰۰ میل',
    diagram: _DiagramKind.stud,
  ),
  'wallpost': _HelpSpec(
    title: 'وال‌پست (نگهدارنده دیوار)',
    subtitle: 'در اجرای وال‌پست از ورق خم‌کاری (منقطع/کشویی) یا ناودانی/نبشی استفاده می‌شود.',
    formulaOrRule: 'می‌توانید ورودی را مستقیم به کیلوگرم بدهید تا متراژ و شاخه را حساب کند (و برعکس).',
    example: 'مثال: ورق ۲ میل با عرض بازشده ۲۵ سانت = ۳٫۹۲۵ کیلوگرم در هر متر',
    diagram: _DiagramKind.wallpost,
  ),
  'gutter': _HelpSpec(
    title: 'آبرو (شیروانی، جعبه‌ای، لندنی، فیتیله‌ای)',
    subtitle: 'وزن آبرو به ضخامت ورق گالوانیزه و «عرض برش ورق پیش از خم‌کاری» بستگی دارد.',
    formulaOrRule: 'وزن هر متر = عرض برش بازشده (متر) × ضخامت (میل) × چگالی',
    example: 'مثال: آبرو عرض ۵۰ سانت، ضخامت ۱ میل = ۳٫۹۲۵ کگ در هر متر طول',
    diagram: _DiagramKind.gutter,
  ),
  'ghameh': _HelpSpec(
    title: 'قامه / بولت عصایی / انکر خم‌دار',
    subtitle: 'از میلگرد با طول بازشده روی محور خم ساخته می‌شود و می‌تواند مهره و واشر هم داشته باشد.',
    formulaOrRule: 'طول هر عدد = مجموع طول ساق و خم قبل از خم‌کاری (روی محور میله)',
    example: 'مثال: قامه میلگرد ۱۸ به طول بازشده ۵۰ سانت ≈ ۱٫۰۲ کگ (+ وزن مهره)',
    diagram: _DiagramKind.ghameh,
  ),
  'mesh': _HelpSpec(
    title: 'مش جوشی مستطیلی',
    subtitle: 'شبکه میلگرد یا مفتول جوش‌خورده با طول و عرض پنل، قطر مفتول‌ها و تعداد سیم‌های طولی/عرضی.',
    formulaOrRule: 'وزن پنل از جمع طول واقعی همه سیم‌های طولی و عرضی حساب می‌شود.',
    example: 'تبدیل بین برگ/پنل، مترمربع، کیلوگرم و بسته',
    diagram: _DiagramKind.mesh,
  ),
  'mesh_area': _HelpSpec(
    title: 'توری بر مبنای مترمربع (پرسی، حصاری، گابیون)',
    subtitle: 'اگر سفارش شما بر حسب مترمربع است (مثلاً ۱۱ مترمربع)، وزن هر مترمربع را از جدول انتخاب یا وارد کنید.',
    formulaOrRule: 'وزن کل = مساحت (مترمربع) × وزن یک مترمربع',
    example: 'مثال: ۱۱ مترمربع توری پرسی ۲ کگ/م² = ۲۲ کیلوگرم',
    diagram: _DiagramKind.mesh,
  ),
  'piece_pack': _HelpSpec(
    title: 'رابیتس و توری بسته‌ای',
    subtitle: 'بر اساس وزن واقعی هر برگ/رول و مساحت مفید هر برگ/رول کار می‌کند.',
    formulaOrRule: 'تعداد ستون رابیتس به‌تنهایی وزن را تعیین نمی‌کند؛ وزن برگ مبناست.',
    example: 'مثال: رابیتس ۹۰۰ گرمی با مساحت ۱٫۴۴ مترمربع',
    diagram: _DiagramKind.mesh,
  ),
  'unit_item': _HelpSpec(
    title: 'قطعه تکی، اتصالات، مهره و واشر',
    subtitle: 'هر کالایی که وزن واحد هر یک عدد آن مشخص است (فلنج، زانویی، مهره، پیچ).',
    formulaOrRule: 'تبدیل دقیق بین تعداد عدد، وزن (کیلو/تن) و کارتن/بسته',
    example: 'مثال: ۱ تن پیچ ۲٫۵ کیلویی = ۴۰۰ عدد = ۴۰ بسته ۱۰ عددی',
    diagram: _DiagramKind.unitItem,
  ),
  'light_heavy': _HelpSpec(
    title: 'تفاوت «سبک» و «سنگین» در بازار آهن',
    subtitle: 'در ابعاد بیرونی مساوی، وزن شاخه سبک و سنگین به‌خاطر ضخامت جداره یا استاندارد تولید متفاوت است.',
    formulaOrRule: 'قوطی/لوله: ضخامت کمتر vs بیشتر • هاش: HEA vs HEB • ناودانی: روس vs اروپا',
    example: 'قوطی ۴۰×۴۰ سبک = ۱۴ کگ، ولی سنگین = ۱۷٫۱ کگ (هر دو ۶ متری)',
    diagram: _DiagramKind.lightHeavy,
  ),
  'order_qty': _HelpSpec(
    title: 'چرا بخش (۲) «مقدار سفارش» وجود دارد؟',
    subtitle: 'بخش (۱) فقط وزنِ «یک متر» یا «یک شاخه» را می‌سازد. بخش (۲) حجم سفارش شماست تا تبدیل به بقیه واحدها انجام شود.',
    formulaOrRule: 'سفارش شما (کیلو، متر، شاخه، مترمربع یا بندیل) ➔ معادل همه واحدهای دیگر',
    example: 'اگر مشتری «۵۰۰ کیلو وال‌پست» خواست، مقدار=۵۰۰ و واحد=کیلوگرم بدهید تا متراژ و شاخه را بگوید.',
    diagram: _DiagramKind.orderQty,
  ),
  'cut_piece': _HelpSpec(
    title: 'قطعه برش‌خورده (عدد) و محاسبه پرت',
    subtitle: 'تعداد «عدد» قطعه کوچک برش‌خورده را از «شاخه/ورق کامل فابریک» جدا می‌کند.',
    formulaOrRule: 'تعداد شاخه/شیت فابریک لازم و مقدار باقیمانده (پرت) خودکار حساب می‌شود.',
    example: 'مثال: ۱۵ عدد برش ۱٫۵ متری از میلگرد ۱۲ متری ➔ ۲ شاخه لازم + ۱٫۵ متر پرت',
    diagram: _DiagramKind.cutPiece,
  ),
  'bundle': _HelpSpec(
    title: 'شاخه / برگ و بندیل / دسته',
    subtitle: 'واحد بسته‌بندی کارخانه (تعداد شاخه یا برگ در هر بندیل/بسته) را برای تبدیل کامل به کار می‌برد.',
    formulaOrRule: 'تعداد بندیل + باقی‌مانده خرد به‌صورت مجزا نمایش داده می‌شود.',
    example: 'مثال: ۲۵۰ شاخه در بندیل‌های ۱۰۰ تایی = ۲ بندیل + ۵۰ شاخه',
    diagram: _DiagramKind.bundle,
  ),
  'services': _HelpSpec(
    title: 'خدمات کارگاهی و قیمت تمام‌شده',
    subtitle: 'هزینه برش، رزوه و خم، پانچ، لیزر، دریل یا هر خدمت دلخواه را بر حسب واحد خودش اضافه می‌کند.',
    formulaOrRule: 'قیمت نهایی = قیمت پایه کالا + جمع خدمات + کرایه حمل + مالیات',
    example: 'می‌توانید نرخ خدمت را به کیلو، متر، شاخه، تعداد سوراخ یا مبلغ ثابت بدهید.',
    diagram: _DiagramKind.services,
  ),
  'density': _HelpSpec(
    title: 'جنس و چگالی فلز',
    subtitle: 'یک سایز ثابت در فلزات مختلف وزن متفاوتی دارد (مثلاً آلومینیوم حدود یک‌سوم فولاد است).',
    formulaOrRule: 'فولاد ۷۸۵۰ • استیل ۳۰۴: ۷۹۰۰ • آلومینیوم: ۲۷۰۰ • مس: ۸۹۶۰ kg/m³',
    example: 'اگر باسکول جنس خاصی می‌خواهید «جنس دلخواه» را انتخاب کنید.',
    diagram: _DiagramKind.density,
  ),
  'window': _HelpSpec(
    title: 'بازه زمانی نرخ‌ها',
    subtitle: 'بر اساس تاریخ اعلامِ خود منبع است (نه ساعت دانلود گوشی).',
    formulaOrRule: '۱ هفته، ۱ ماه، یا همه زمان‌ها — هر تب می‌تواند بازه مستقل یا پیرو تب اطلاعات داشته باشد.',
    example: 'اگر نتیجه‌ای کم بود بازه را به ۱ ماه یا همه زمان‌ها تغییر دهید.',
    diagram: _DiagramKind.window,
  ),
  'tax': _HelpSpec(
    title: 'مالیات بر ارزش افزوده (نمایشی)',
    subtitle: 'وقتی روشن باشد، درصد انتخابی (پیش‌فرض ۱۳٪) به صورت ظاهری به قیمت‌های تومان اضافه می‌شود.',
    formulaOrRule: 'دادهٔ اصلی ثبت‌شده از فروشنده هرگز تغییر نمی‌کند.',
    example: 'مناسب مقایسه فاکتور رسمی و غیررسمی',
    diagram: _DiagramKind.tax,
  ),
  'basis': _HelpSpec(
    title: 'مبنای مقایسه و قیمت واحد',
    subtitle: 'مقایسهٔ کیلویی با شاخه‌ای فقط وقتی انجام می‌شود که وزن دقیق همان شاخه از منبع روشن باشد.',
    formulaOrRule: '«واحد اصلی» هر فروشنده را در واحد خودش نگه می‌دارد؛ «تبدیل به کیلو» فقط با وزن صریح تبدیل می‌کند.',
    example: 'هرگز وزن تخمینی برای ارزان‌تر نشان دادن یک فروشنده ساخته نمی‌شود.',
    diagram: _DiagramKind.basis,
  ),
  'sort': _HelpSpec(
    title: 'ترتیب نمایش پیشنهادها',
    subtitle: 'می‌توانید بر اساس جدیدترین تاریخ اعلام، ارزان‌ترین هم‌مبنا یا گران‌ترین هم‌مبنا مرتب کنید.',
    formulaOrRule: 'ردیف‌های بدون قیمت یا واحد نامشخص همیشه جدا از رتبه‌بندی عددی می‌مانند.',
    example: 'جدیدترین اول = تازه‌ترین اعلان‌های بازار در صدر',
    diagram: _DiagramKind.sort,
  ),
  'spec_filter': _HelpSpec(
    title: 'سایز، ضخامت، گرید و استاندارد',
    subtitle: 'سایز = نمره مقطع (مثلاً میلگرد ۱۶)، ضخامت = میلی‌متر ورق/قوطی، گرید = آلیاژ و استاندارد (مثل A3، ST37).',
    formulaOrRule: 'خالی گذاشتن هر معیار یعنی شامل همه مقادیر آن معیار می‌شود.',
    example: 'مثال: ورق + ضخامت ۸ میل، یا میلگرد + سایز ۱۶ + گرید A3',
    diagram: _DiagramKind.specFilter,
  ),
  'range_stats': _HelpSpec(
    title: 'شاخص‌های رنج‌گیری (کف، میانه، میانگین، سقف)',
    subtitle: 'نشان می‌دهد بازار برای مشخصات انتخابی شما در چه محدوده‌ای قیمت داده است.',
    formulaOrRule: 'کف = کمترین قیمت • میانه = وسط بازار (مقاوم در برابر قیمت‌های پرت) • سقف = بیشترین قیمت',
    example: 'برای مقایسه منصفانه، فروشندگان با واحد یا مالیات متفاوت جداگانه رنج می‌شوند.',
    diagram: _DiagramKind.rangeStats,
  ),
  'chart_mode': _HelpSpec(
    title: 'حالت‌های نمودار تاریخچه',
    subtitle: 'قیمت هر ثبت تک‌تک اعلان‌های یک فروشنده را نشان می‌دهد؛ شاخص‌های رنج تغییرات کف/میانه/سقف بازار را.',
    formulaOrRule: 'گذشته ساختگی تولید نمی‌شود؛ فقط داده‌های واقعی ثبت‌شده رسم می‌شوند.',
    example: 'روی دایره راهنمای بالای نمودار خطوط شاخص را روشن/خاموش کنید.',
    diagram: _DiagramKind.chartMode,
  ),
  'city_scope': _HelpSpec(
    title: 'شهر سراسری و محل بارگیری',
    subtitle: 'شهر انتخابی در تب اطلاعات، قیمت‌ها، رنج‌گیری و نمودار را به آن شهر محدود می‌کند.',
    formulaOrRule: 'روی ماشین حساب دستی اثری ندارد چون نرخ ماشین حساب ورودی شماست.',
    example: '«همه شهرها» = نمایش پیشنهادهای سراسر کشور',
    diagram: _DiagramKind.cityScope,
  ),
  'sources': _HelpSpec(
    title: 'منابع سرور، هوش جستجوگر ۲ و پشتیبان‌گیری',
    subtitle: 'برنامه فهرست منابع معتبر را از سرور می‌خواند و نرخ‌ها را مستقیم با تحلیل دقیق جدول و متن می‌گیرد.',
    formulaOrRule: 'حالت «رد کردن منابع تازه‌اسکن‌شده» برای جلوگیری از تکرار و سرعت بیشتر اسکن است.',
    example: 'با پشتیبان‌گیری JSON می‌توانید همه داده‌های جمع‌شده را نگه دارید.',
    diagram: _DiagramKind.sources,
  ),
};

Future<void> showVisualHelp(
  BuildContext context,
  String topic, {
  String? titleOverride,
}) async {
  final spec = _helpSpecs[topic] ??
      const _HelpSpec(
        title: 'راهنمای معیار',
        subtitle: 'این معیار ورودی یا فیلتر محاسبه و جستجو را مشخص می‌کند.',
        formulaOrRule: 'مقادیر با واحد صریح وارد یا انتخاب می‌شوند.',
        example: 'برای دقت بیشتر همیشه واحد مشخص (میلی‌متر، سانتی‌متر، متر یا کیلوگرم) را بررسی کنید.',
        diagram: _DiagramKind.orderQty,
      );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.architecture, color: teal, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titleOverride ?? spec.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 185,
              decoration: BoxDecoration(
                color: const Color(0xfff5f9fa),
                border: Border.all(color: const Color(0xffd7e5e8)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: _VisualHelpPainter(spec.diagram),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              spec.subtitle,
              style: const TextStyle(fontSize: 13, height: 1.7, color: ink),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: teal.withOpacity(.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: teal.withOpacity(.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spec.formulaOrRule,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec.example,
                    style: const TextStyle(fontSize: 11.5, color: muted, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VisualHelpPainter extends CustomPainter {
  final _DiagramKind kind;
  const _VisualHelpPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    final steelFill = Paint()
      ..color = const Color(0xffb8ccd4)
      ..style = PaintingStyle.fill;
    final steelDarkFill = Paint()
      ..color = const Color(0xff89a6b2)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = ink
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final dimLine = Paint()
      ..color = const Color(0xffd64545)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final accentLine = Paint()
      ..color = teal
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    void label(String text, Offset center,
        {Color color = const Color(0xffb83232), double fontSize = 11.5, FontWeight weight = FontWeight.bold}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            fontFamily: 'Vazirmatn',
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }

    void dimArrow(Offset a, Offset b, String text, {Offset textOffset = const Offset(0, -10)}) {
      canvas.drawLine(a, b, dimLine);
      final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
      const tick = 5.0;
      canvas.drawLine(a, a + Offset(tick * math.cos(angle + 0.5), tick * math.sin(angle + 0.5)), dimLine);
      canvas.drawLine(a, a + Offset(tick * math.cos(angle - 0.5), tick * math.sin(angle - 0.5)), dimLine);
      canvas.drawLine(b, b - Offset(tick * math.cos(angle + 0.5), tick * math.sin(angle + 0.5)), dimLine);
      canvas.drawLine(b, b - Offset(tick * math.cos(angle - 0.5), tick * math.sin(angle - 0.5)), dimLine);
      label(text, Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2) + textOffset);
    }

    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (kind) {
      case _DiagramKind.plate:
      case _DiagramKind.cutPlate:
        final poly = Path()
          ..moveTo(cx - 85, cy + 20)
          ..lineTo(cx + 35, cy + 20)
          ..lineTo(cx + 85, cy - 25)
          ..lineTo(cx - 35, cy - 25)
          ..close();
        canvas.drawPath(poly, steelFill);
        canvas.drawPath(poly, outline);
        final side = Path()
          ..moveTo(cx - 85, cy + 20)
          ..lineTo(cx + 35, cy + 20)
          ..lineTo(cx + 35, cy + 34)
          ..lineTo(cx - 85, cy + 34)
          ..close();
        canvas.drawPath(side, steelDarkFill);
        canvas.drawPath(side, outline);
        final rSide = Path()
          ..moveTo(cx + 35, cy + 20)
          ..lineTo(cx + 85, cy - 25)
          ..lineTo(cx + 85, cy - 11)
          ..lineTo(cx + 35, cy + 34)
          ..close();
        canvas.drawPath(rSide, steelDarkFill);
        canvas.drawPath(rSide, outline);
        dimArrow(Offset(cx - 85, cy + 50), Offset(cx + 35, cy + 50),
            kind == _DiagramKind.cutPlate ? 'عرض (cm / mm)' : 'عرض ورق (W)',
            textOffset: const Offset(0, 12));
        dimArrow(Offset(cx + 50, cy + 34), Offset(cx + 100, cy - 11),
            kind == _DiagramKind.cutPlate ? 'طول قطعه' : 'طول (L)',
            textOffset: const Offset(28, 8));
        dimArrow(Offset(cx - 102, cy + 20), Offset(cx - 102, cy + 34),
            'ضخامت (t)',
            textOffset: const Offset(-34, 0));
        break;

      case _DiagramKind.rebar:
        canvas.drawCircle(Offset(cx - 55, cy), 38, steelFill);
        canvas.drawCircle(Offset(cx - 55, cy), 38, outline);
        dimArrow(Offset(cx - 93, cy), Offset(cx - 17, cy), 'قطر (سایز mm)', textOffset: const Offset(0, -16));
        final rod = Rect.fromLTWH(cx + 15, cy - 12, 115, 24);
        canvas.drawRect(rod, steelFill);
        canvas.drawRect(rod, outline);
        for (var x = cx + 25; x < cx + 125; x += 14) {
          canvas.drawLine(Offset(x, cy - 12), Offset(x + 6, cy + 12), outline);
        }
        dimArrow(Offset(cx + 15, cy + 32), Offset(cx + 130, cy + 32), 'طول شاخه (مثلاً ۱۲ متر)', textOffset: const Offset(0, 12));
        break;

      case _DiagramKind.rhs:
        // Left: light (thin wall), Right: heavy (thick wall)
        final lOuter = Rect.fromCenter(center: Offset(cx - 65, cy), width: 64, height: 64);
        final lInner = Rect.fromCenter(center: Offset(cx - 65, cy), width: 52, height: 52);
        canvas.drawPath(Path()..addRect(lOuter)..addRect(lInner)..fillType = PathFillType.evenOdd, steelFill);
        canvas.drawRect(lOuter, outline);
        canvas.drawRect(lInner, outline);
        label('سبک (دیواره نازک)', Offset(cx - 65, cy + 48), color: teal);

        final rOuter = Rect.fromCenter(center: Offset(cx + 65, cy), width: 64, height: 64);
        final rInner = Rect.fromCenter(center: Offset(cx + 65, cy), width: 40, height: 40);
        canvas.drawPath(Path()..addRect(rOuter)..addRect(rInner)..fillType = PathFillType.evenOdd, steelDarkFill);
        canvas.drawRect(rOuter, outline);
        canvas.drawRect(rInner, outline);
        label('سنگین (دیواره ضخیم)', Offset(cx + 65, cy + 48), color: ink);
        dimArrow(Offset(cx + 33, cy - 44), Offset(cx + 97, cy - 44), 'عرض بیرونی مساوی', textOffset: const Offset(0, -12));
        dimArrow(Offset(cx + 85, cy), Offset(cx + 97, cy), 't', textOffset: const Offset(16, -2));
        break;

      case _DiagramKind.pipe:
        final p1 = Offset(cx - 65, cy);
        canvas.drawCircle(p1, 36, steelFill);
        canvas.drawCircle(p1, 29, Paint()..color = const Color(0xfff5f9fa));
        canvas.drawCircle(p1, 36, outline);
        canvas.drawCircle(p1, 29, outline);
        label('سبک (ض ۲ میل)', Offset(cx - 65, cy + 52), color: teal);

        final p2 = Offset(cx + 65, cy);
        canvas.drawCircle(p2, 36, steelDarkFill);
        canvas.drawCircle(p2, 23, Paint()..color = const Color(0xfff5f9fa));
        canvas.drawCircle(p2, 36, outline);
        canvas.drawCircle(p2, 23, outline);
        label('سنگین (ض ۲٫۵ میل)', Offset(cx + 65, cy + 52), color: ink);
        dimArrow(Offset(cx + 29, cy - 46), Offset(cx + 101, cy - 46), 'قطر خارجی (OD)', textOffset: const Offset(0, -12));
        break;

      case _DiagramKind.angle:
        final p = Path()
          ..moveTo(cx - 45, cy - 50)
          ..lineTo(cx - 31, cy - 50)
          ..lineTo(cx - 31, cy + 28)
          ..lineTo(cx + 48, cy + 28)
          ..lineTo(cx + 48, cy + 42)
          ..lineTo(cx - 45, cy + 42)
          ..close();
        canvas.drawPath(p, steelFill);
        canvas.drawPath(p, outline);
        dimArrow(Offset(cx - 62, cy - 50), Offset(cx - 62, cy + 42), 'بال ۱', textOffset: const Offset(-20, 0));
        dimArrow(Offset(cx - 45, cy + 58), Offset(cx + 48, cy + 58), 'بال ۲ (مثلاً ۸۰ میل)', textOffset: const Offset(0, 12));
        dimArrow(Offset(cx - 45, cy - 58), Offset(cx - 31, cy - 58), 'ضخامت t', textOffset: const Offset(10, -12));
        break;

      case _DiagramKind.channel:
        final p = Path()
          ..moveTo(cx - 45, cy - 45)
          ..lineTo(cx + 40, cy - 45)
          ..lineTo(cx + 40, cy - 30)
          ..lineTo(cx - 30, cy - 30)
          ..lineTo(cx - 30, cy + 30)
          ..lineTo(cx + 40, cy + 30)
          ..lineTo(cx + 40, cy + 45)
          ..lineTo(cx - 45, cy + 45)
          ..close();
        canvas.drawPath(p, steelFill);
        canvas.drawPath(p, outline);
        dimArrow(Offset(cx - 62, cy - 45), Offset(cx - 62, cy + 45), 'ارتفاع جان (H)', textOffset: const Offset(-38, 0));
        dimArrow(Offset(cx - 45, cy - 60), Offset(cx + 40, cy - 60), 'عرض بال (B)', textOffset: const Offset(0, -12));
        dimArrow(Offset(cx + 55, cy + 30), Offset(cx + 55, cy + 45), 'ض بال (tf)', textOffset: const Offset(30, 0));
        label('روس = سبک‌تر  |  اروپا UPN = سنگین‌تر', Offset(cx, cy + 68), color: teal);
        break;

      case _DiagramKind.beam:
      case _DiagramKind.hbeam:
        final isH = kind == _DiagramKind.hbeam;
        final w = isH ? 96.0 : 66.0;
        final h = 92.0;
        final tf = isH ? 15.0 : 12.0;
        final tw = isH ? 13.0 : 9.0;
        final p = Path()
          ..moveTo(cx - w / 2, cy - h / 2)
          ..lineTo(cx + w / 2, cy - h / 2)
          ..lineTo(cx + w / 2, cy - h / 2 + tf)
          ..lineTo(cx + tw / 2, cy - h / 2 + tf)
          ..lineTo(cx + tw / 2, cy + h / 2 - tf)
          ..lineTo(cx + w / 2, cy + h / 2 - tf)
          ..lineTo(cx + w / 2, cy + h / 2)
          ..lineTo(cx - w / 2, cy + h / 2)
          ..lineTo(cx - w / 2, cy + h / 2 - tf)
          ..lineTo(cx - tw / 2, cy + h / 2 - tf)
          ..lineTo(cx - tw / 2, cy - h / 2 + tf)
          ..lineTo(cx - w / 2, cy - h / 2 + tf)
          ..close();
        canvas.drawPath(p, isH ? steelDarkFill : steelFill);
        canvas.drawPath(p, outline);
        dimArrow(Offset(cx - w / 2 - 18, cy - h / 2), Offset(cx - w / 2 - 18, cy + h / 2), 'ارتفاع (H)', textOffset: const Offset(-32, 0));
        dimArrow(Offset(cx - w / 2, cy - h / 2 - 14), Offset(cx + w / 2, cy - h / 2 - 14), 'عرض بال (B)', textOffset: const Offset(0, -12));
        dimArrow(Offset(cx - tw / 2, cy + 6), Offset(cx + tw / 2, cy + 6), 'جان tw', textOffset: const Offset(28, -2));
        if (isH) {
          label('سبک = HEA  |  سنگین = HEB', Offset(cx, cy + 66), color: teal);
        }
        break;

      case _DiagramKind.tee:
        final p = Path()
          ..moveTo(cx - 50, cy - 42)
          ..lineTo(cx + 50, cy - 42)
          ..lineTo(cx + 50, cy - 28)
          ..lineTo(cx + 7, cy - 28)
          ..lineTo(cx + 7, cy + 45)
          ..lineTo(cx - 7, cy + 45)
          ..lineTo(cx - 7, cy - 28)
          ..lineTo(cx - 50, cy - 28)
          ..close();
        canvas.drawPath(p, steelFill);
        canvas.drawPath(p, outline);
        dimArrow(Offset(cx - 50, cy - 56), Offset(cx + 50, cy - 56), 'عرض بال (B)', textOffset: const Offset(0, -12));
        dimArrow(Offset(cx - 65, cy - 42), Offset(cx - 65, cy + 45), 'ارتفاع کل (H)', textOffset: const Offset(-32, 0));
        break;

      case _DiagramKind.flat:
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: 140, height: 26);
        canvas.drawRect(rect, steelFill);
        canvas.drawRect(rect, outline);
        dimArrow(Offset(cx - 70, cy + 28), Offset(cx + 70, cy + 28), 'عرض تسمه (mm / cm)', textOffset: const Offset(0, 12));
        dimArrow(Offset(cx + 85, cy - 13), Offset(cx + 85, cy + 13), 'ضخامت (t)', textOffset: const Offset(30, 0));
        break;

      case _DiagramKind.bar:
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: 70, height: 70);
        canvas.drawRect(rect, steelFill);
        canvas.drawRect(rect, outline);
        label('توپر (Solid)', Offset(cx, cy), color: ink);
        dimArrow(Offset(cx - 35, cy + 48), Offset(cx + 35, cy + 48), 'عرض (B)', textOffset: const Offset(0, 12));
        dimArrow(Offset(cx - 52, cy - 35), Offset(cx - 52, cy + 35), 'ارتفاع (H)', textOffset: const Offset(-28, 0));
        break;

      case _DiagramKind.hex:
        final hex = Path();
        const r = 46.0;
        for (var i = 0; i < 6; i++) {
          final a = (i * 60) * math.pi / 180;
          final pt = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
          if (i == 0) {
            hex.moveTo(pt.dx, pt.dy);
          } else {
            hex.lineTo(pt.dx, pt.dy);
          }
        }
        hex.close();
        canvas.drawPath(hex, steelFill);
        canvas.drawPath(hex, outline);
        final flatHalf = r * math.sqrt(3) / 2;
        dimArrow(Offset(cx, cy - flatHalf), Offset(cx, cy + flatHalf), 'فاصله دو وجه (S)', textOffset: const Offset(55, 0));
        break;

      case _DiagramKind.stud:
        // Deck base line + shear stud (head + shank)
        canvas.drawLine(Offset(cx - 100, cy + 42), Offset(cx + 100, cy + 42), outline);
        final head = Rect.fromCenter(center: Offset(cx, cy - 42), width: 46, height: 14);
        final shank = Rect.fromLTWH(cx - 13, cy - 35, 26, 77);
        canvas.drawRect(shank, steelFill);
        canvas.drawRect(head, steelDarkFill);
        canvas.drawRect(shank, outline);
        canvas.drawRect(head, outline);
        dimArrow(Offset(cx - 13, cy + 6), Offset(cx + 13, cy + 6), 'قطر (d) مثلاً ۱۹', textOffset: const Offset(48, 0));
        dimArrow(Offset(cx - 46, cy - 49), Offset(cx - 46, cy + 42), 'طول (L) مثلاً ۱۰۰', textOffset: const Offset(-45, 0));
        label('رایج عرشه فولادی: ۱۹×۱۰۰ میل (~۲۶۲ گرم)', Offset(cx, cy + 64), color: teal);
        break;

      case _DiagramKind.wallpost:
        // Wall + U-channel/bent wallpost holding wall
        final wall = Rect.fromLTWH(cx - 80, cy - 45, 70, 90);
        canvas.drawRect(wall, Paint()..color = const Color(0xffe7d5c3));
        canvas.drawRect(wall, outline);
        final wp = Path()
          ..moveTo(cx - 10, cy - 52)
          ..lineTo(cx + 42, cy - 52)
          ..lineTo(cx + 42, cy + 52)
          ..lineTo(cx - 10, cy + 52)
          ..lineTo(cx - 10, cy + 40)
          ..lineTo(cx + 30, cy + 40)
          ..lineTo(cx + 30, cy - 40)
          ..lineTo(cx - 10, cy - 40)
          ..close();
        canvas.drawPath(wp, steelDarkFill);
        canvas.drawPath(wp, outline);
        label('دیوار', Offset(cx - 45, cy), color: ink);
        label('وال‌پست', Offset(cx + 68, cy), color: teal);
        label('ورود کیلوگرم ➔ متراژ و شاخه (و برعکس)', Offset(cx, cy + 72), color: ink);
        break;

      case _DiagramKind.gutter:
        // Box gutter U-shape with flanges
        final g = Path()
          ..moveTo(cx - 75, cy - 25)
          ..lineTo(cx - 52, cy - 25)
          ..lineTo(cx - 42, cy + 30)
          ..lineTo(cx + 42, cy + 30)
          ..lineTo(cx + 52, cy - 25)
          ..lineTo(cx + 75, cy - 25);
        canvas.drawPath(g, Paint()..color = teal..strokeWidth = 4..style = PaintingStyle.stroke);
        dimArrow(Offset(cx - 75, cy + 50), Offset(cx + 75, cy + 50), 'عرض برش بازشده ورق (مثلاً ۵۰ سانت)', textOffset: const Offset(0, 14));
        label('آبرو شیروانی (ضخامت ورق × عرض بازشده × متراژ)', Offset(cx, cy - 54), color: ink);
        break;

      case _DiagramKind.ghameh:
        // J / L hooked bolt with thread & nut
        final p = Path()
          ..moveTo(cx - 60, cy + 35)
          ..lineTo(cx - 60, cy - 20)
          ..lineTo(cx + 60, cy - 20);
        canvas.drawPath(p, Paint()..color = ink..strokeWidth = 7..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
        // Threads + nut on right
        for (var x = cx + 22; x <= cx + 56; x += 6) {
          canvas.drawLine(Offset(x, cy - 26), Offset(x, cy - 14), dimLine);
        }
        canvas.drawRect(Rect.fromCenter(center: Offset(cx + 38, cy - 20), width: 12, height: 18), steelDarkFill);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx + 38, cy - 20), width: 12, height: 18), outline);
        label('رزوه + مهره', Offset(cx + 38, cy - 42), color: teal);
        label('طول بازشده = ساق + طول خم روی محور میلگرد', Offset(cx + 6, cy + 54), color: ink);
        break;

      case _DiagramKind.mesh:
        for (var x = cx - 75; x <= cx + 75; x += 30) {
          canvas.drawLine(Offset(x, cy - 45), Offset(x, cy + 45), outline);
        }
        for (var y = cy - 45; y <= cy + 45; y += 30) {
          canvas.drawLine(Offset(cx - 75, y), Offset(cx + 75, y), outline);
        }
        dimArrow(Offset(cx - 75, cy + 58), Offset(cx + 75, cy + 58), 'مساحت = مترمربع (مثلاً ۱۱ مترمربع)', textOffset: const Offset(0, 14));
        break;

      case _DiagramKind.unitItem:
        canvas.drawCircle(Offset(cx - 45, cy), 26, steelDarkFill);
        canvas.drawCircle(Offset(cx - 45, cy), 10, Paint()..color = const Color(0xfff5f9fa));
        canvas.drawCircle(Offset(cx - 45, cy), 26, outline);
        canvas.drawCircle(Offset(cx - 45, cy), 10, outline);
        canvas.drawRect(Rect.fromLTWH(cx + 15, cy - 22, 55, 44), steelFill);
        canvas.drawRect(Rect.fromLTWH(cx + 15, cy - 22, 55, 44), outline);
        label('وزن ۱ عدد ➔ تبدیل عدد ↔ کارتن ↔ کیلو', Offset(cx, cy + 54), color: ink);
        break;

      case _DiagramKind.lightHeavy:
        final l1 = Rect.fromCenter(center: Offset(cx - 65, cy - 5), width: 58, height: 58);
        final l2 = Rect.fromCenter(center: Offset(cx - 65, cy - 5), width: 48, height: 48);
        canvas.drawPath(Path()..addRect(l1)..addRect(l2)..fillType = PathFillType.evenOdd, steelFill);
        canvas.drawRect(l1, outline);
        canvas.drawRect(l2, outline);
        label('سبک (وزن کمتر)', Offset(cx - 65, cy + 42), color: teal);

        final h1 = Rect.fromCenter(center: Offset(cx + 65, cy - 5), width: 58, height: 58);
        final h2 = Rect.fromCenter(center: Offset(cx + 65, cy - 5), width: 34, height: 34);
        canvas.drawPath(Path()..addRect(h1)..addRect(h2)..fillType = PathFillType.evenOdd, steelDarkFill);
        canvas.drawRect(h1, outline);
        canvas.drawRect(h2, outline);
        label('سنگین (ضخامت بیشتر)', Offset(cx + 65, cy + 42), color: ink);
        label('سایز ظاهری یکی است؛ ضخامت یا استاندارد فرق دارد', Offset(cx, cy + 68), color: const Color(0xffb83232));
        break;

      case _DiagramKind.orderQty:
        final b1 = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 135, cy - 26, 78, 52), const Radius.circular(10));
        final b2 = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 39, cy - 26, 78, 52), const Radius.circular(10));
        final b3 = RRect.fromRectAndRadius(Rect.fromLTWH(cx + 57, cy - 26, 78, 52), const Radius.circular(10));
        canvas.drawRRect(b1, steelFill);
        canvas.drawRRect(b2, Paint()..color = teal.withOpacity(.2));
        canvas.drawRRect(b3, steelDarkFill);
        canvas.drawRRect(b1, outline);
        canvas.drawRRect(b2, accentLine);
        canvas.drawRRect(b3, outline);
        label('۱. مشخصات جنس', Offset(cx - 96, cy), color: ink, fontSize: 10.5);
        label('۲. مقدار سفارش شما', Offset(cx, cy), color: teal, fontSize: 10.5);
        label('همه معادل‌ها', Offset(cx + 96, cy), color: ink, fontSize: 10.5);
        label('کیلو ↔ متر ↔ شاخه ↔ بندیل ↔ تن', Offset(cx, cy + 54), color: ink);
        break;

      case _DiagramKind.cutPiece:
        final stock = Rect.fromLTWH(cx - 115, cy - 22, 230, 32);
        canvas.drawRect(stock, steelFill);
        canvas.drawRect(stock, outline);
        for (var i = 0; i < 3; i++) {
          final part = Rect.fromLTWH(cx - 115 + i * 62, cy - 22, 62, 32);
          canvas.drawRect(part, Paint()..color = teal.withOpacity(.22));
          canvas.drawRect(part, outline);
          label('عدد ${i + 1}', Offset(cx - 84 + i * 62, cy - 6), color: ink, fontSize: 10);
        }
        final waste = Rect.fromLTWH(cx - 115 + 186, cy - 22, 44, 32);
        canvas.drawRect(waste, Paint()..color = const Color(0xffe57373).withOpacity(.35));
        canvas.drawRect(waste, outline);
        label('پرت', Offset(cx + 93, cy - 6), color: const Color(0xffb83232), fontSize: 10);
        dimArrow(Offset(cx - 115, cy + 28), Offset(cx + 115, cy + 28), 'طول شیت / شاخه فابریک', textOffset: const Offset(0, 14));
        break;

      case _DiagramKind.bundle:
        for (var i = 0; i < 6; i++) {
          canvas.drawCircle(Offset(cx - 50 + (i % 3) * 18, cy - 12 + (i ~/ 3) * 18), 7, steelDarkFill);
          canvas.drawCircle(Offset(cx - 50 + (i % 3) * 18, cy - 12 + (i ~/ 3) * 18), 7, outline);
        }
        canvas.drawRect(Rect.fromLTWH(cx - 64, cy - 24, 64, 42), accentLine);
        label('۱ بندیل = N شاخه', Offset(cx - 32, cy + 40), color: teal);
        canvas.drawRect(Rect.fromLTWH(cx + 35, cy - 6, 75, 10), steelFill);
        canvas.drawRect(Rect.fromLTWH(cx + 35, cy - 6, 75, 10), outline);
        label('۱ شاخه', Offset(cx + 72, cy + 22), color: ink);
        break;

      case _DiagramKind.services:
        final items = ['برش', 'رزوه و خم', 'پانچ', 'لیزر', 'دریل'];
        for (var i = 0; i < items.length; i++) {
          final x = cx - 108 + i * 54;
          final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, cy - 16), width: 48, height: 34), const Radius.circular(8));
          canvas.drawRRect(r, Paint()..color = teal.withOpacity(.14));
          canvas.drawRRect(r, accentLine);
          label(items[i], Offset(x, cy - 16), color: ink, fontSize: 9.5);
        }
        label('جمع خدمات + قیمت پایه + حمل + مالیات = قیمت نهایی', Offset(cx, cy + 36), color: ink, fontSize: 11);
        break;

      case _DiagramKind.density:
        final mats = [
          ('آلومینیوم', 0.34, const Color(0xff90a4ae)),
          ('فولاد/آهن', 1.0, teal),
          ('مس', 1.14, const Color(0xffd87a4a)),
        ];
        for (var i = 0; i < mats.length; i++) {
          final y = cy - 36 + i * 32;
          canvas.drawRect(Rect.fromLTWH(cx - 20, y - 9, 125 * mats[i].$2, 18), Paint()..color = mats[i].$3);
          label(mats[i].$1, Offset(cx - 65, y), color: ink, fontSize: 11);
        }
        label('یک سایز یکسان، وزن متفاوت در جنس‌های مختلف', Offset(cx, cy + 62), color: muted);
        break;

      case _DiagramKind.window:
      case _DiagramKind.tax:
      case _DiagramKind.basis:
      case _DiagramKind.sort:
      case _DiagramKind.specFilter:
      case _DiagramKind.cityScope:
      case _DiagramKind.sources:
        canvas.drawLine(Offset(cx - 105, cy + 12), Offset(cx + 105, cy + 12), outline);
        for (var i = 0; i < 4; i++) {
          final x = cx - 80 + i * 52;
          canvas.drawCircle(Offset(x, cy + 12), 7, Paint()..color = i == 2 ? teal : steelDarkFill);
          canvas.drawCircle(Offset(x, cy + 12), 7, outline);
        }
        final tagTxt = switch (kind) {
          _DiagramKind.window => 'تاریخ اعلام منبع (۲۴ ساعت ➔ ۱ هفته ➔ ۱ ماه ➔ همه)',
          _DiagramKind.tax => 'قیمت منبع + درصد مالیات (نمایشی؛ اصل داده حفظ می‌شود)',
          _DiagramKind.basis => 'هم‌مبنا: کیلوگرم فقط با وزن معتبر با شاخه مقایسه می‌شود',
          _DiagramKind.sort => 'مرتب‌سازی هم‌مبنا: جدیدترین / ارزان به گران / گران به ارزان',
          _DiagramKind.specFilter => 'فیلتر دقیق: کالا + سایز + ضخامت (mm) + گرید',
          _DiagramKind.cityScope => 'شهر سراسری ➔ فیلتر قیمت‌ها، رنج و نمودار',
          _ => 'سرور منابع + تحلیل متن و جدول واقعی (بدون نرخ جعلی)',
        };
        label(tagTxt, Offset(cx, cy - 26), color: ink, fontSize: 11);
        break;

      case _DiagramKind.rangeStats:
      case _DiagramKind.chartMode:
        // Price axis with low / median / mean / high
        canvas.drawLine(Offset(cx - 110, cy + 20), Offset(cx + 110, cy + 20), outline);
        final pts = [
          (cx - 85, 'کف', const Color(0xff2e7d32)),
          (cx - 15, 'میانه', teal),
          (cx + 22, 'میانگین', ink),
          (cx + 88, 'سقف', const Color(0xffc62828)),
        ];
        for (final p in pts) {
          canvas.drawCircle(Offset(p.$1, cy + 20), 7, Paint()..color = p.$3);
          label(p.$2, Offset(p.$1, cy - 8), color: p.$3, fontSize: 11);
        }
        if (kind == _DiagramKind.chartMode) {
          final path = Path()
            ..moveTo(cx - 85, cy - 22)
            ..lineTo(cx - 25, cy - 42)
            ..lineTo(cx + 30, cy - 28)
            ..lineTo(cx + 88, cy - 52);
          canvas.drawPath(path, accentLine);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _VisualHelpPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
