import 'dart:convert';
import 'dart:async';
import '../data/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/calculator.dart';
import '../domain/market.dart';
import 'common.dart';
import '../domain/money.dart';
import 'product_converter_view.dart';
import 'visual_help.dart';

class CalculatorPage extends StatefulWidget {
  final String city;
  const CalculatorPage({super.key, this.city = ''});
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  bool converterMode = true;
  bool advanced = false;
  bool cutByCount = false;
  String shape = 'round', inputUnit = 'm', priceUnit = 'kg', metal = 'steel';
  final values = <String, TextEditingController>{};
  final density = TextEditingController(text: '۷۸۵۰'),
      quantity = TextEditingController(text: '۱'),
      length = TextEditingController(text: '۱۲'),
      cutWidth = TextEditingController(text: '۳۰۰'),
      cutLength = TextEditingController(text: '۱۵۰۰'),
      price = TextEditingController(),
      tax = TextEditingController(text: '۰'),
      shipping = TextEditingController(text: '۰'),
      services = TextEditingController(text: '۰'),
      waste = TextEditingController(text: '۰');
  WeightResult? result;
  double? total;
  String? error;
  Shape get spec => shapes.firstWhere((s) => s.id == shape);
  @override
  void initState() {
    super.initState();
    resetFields();
  }

  void resetFields() {
    for (final c in values.values) {
      c.dispose();
    }
    values.clear();
    for (final f in spec.fields) {
      values[f.key] = TextEditingController(text: fmt(f.initial, decimals: 6));
    }
    if (!advanced && shape == 'plate') values['b']!.text = '۱';
    if (!advanced && shape == 'catalog') values['kgm']!.clear();
    cutLength.text = shape == 'plate' ? '۴۰۰' : '۱۵۰۰';
    cutWidth.text = '۳۰۰';
    if (!SteelCalculator.cuttableShapes.contains(shape)) {
      cutByCount = false;
      if (inputUnit == 'cut') inputUnit = 'piece';
      if (priceUnit == 'cut') priceUnit = 'kg';
    }
    result = null;
    total = null;
    error = null;
  }

  @override
  void dispose() {
    for (final c in [
      ...values.values,
      density,
      quantity,
      length,
      cutWidth,
      cutLength,
      price,
      tax,
      shipping,
      services,
      waste
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double read(TextEditingController c, {double? fallback}) {
    final v = number(c.text);
    if (v == null) {
      if (fallback != null && c.text.trim().isEmpty) return fallback;
      throw const FormatException(
          'تمام ورودی‌های لازم را با عدد معتبر تکمیل کنید.');
    }
    return v;
  }

  void calculate() {
    try {
      final isCutMode =
          SteelCalculator.cuttableShapes.contains(shape) &&
              (advanced ? inputUnit == 'cut' : cutByCount);
      final effectiveInputUnit = advanced
          ? inputUnit
          : (isCutMode ? 'cut' : 'piece');
      final r = SteelCalculator.calculate(
          shape: shape,
          values: values.map((k, v) => MapEntry(
              k,
              !advanced && shape == 'plate' && k == 'b'
                  ? read(v) * 1000
                  : !advanced && shape == 'catalog' && k == 'kgm'
                      ? read(v) / read(length)
                      : read(v))),
          density: advanced ? read(density) : 7850,
          inputUnit: effectiveInputUnit,
          quantity: read(quantity),
          lengthPerPiece: shape == 'anchorMeasured' ? 1 : read(length),
          wastePercent: advanced ? read(waste) : 0,
          cutLengthMm: isCutMode ? read(cutLength) : null,
          cutWidthMm: isCutMode && shape == 'plate' ? read(cutWidth) : null);
      final p = price.text.trim().isEmpty ? null : read(price);
      final cost = p == null
          ? null
          : SteelCalculator.cost(r, priceUnit, p,
              taxPercent: advanced ? read(tax) : 0,
              shipping: advanced ? read(shipping) : 0,
              services: advanced ? read(services) : 0);
      unawaited(AppLogger.instance.record('calculator', 'calculated', {
        'shape': shape,
        'advanced': advanced,
        'kg': r.kg,
        'priced': cost != null
      }));
      setState(() {
        result = r;
        total = cost;
        error = null;
      });
    } catch (e) {
      unawaited(AppLogger.instance
          .record('calculator', 'validation_failed', {'shape': shape}));
      setState(() {
        result = null;
        total = null;
        error = e is FormatException ? e.message : 'ورودی نامعتبر است.';
      });
    }
  }

  String _helpTopicForShape(String s) => switch (s) {
        'round' => 'rebar',
        'anchor' || 'anchorMeasured' => 'ghameh',
        'ibeam' => 'ibeam_geom',
        'catalog' => 'catalog_kgm',
        'formed' => 'plate',
        'piece' => 'piece_pack',
        'square' => 'bar',
        'bulk' => 'unit_item',
        _ => s,
      };

  Widget numeric(String label, TextEditingController ctl, {String? helpTopic}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextField(
              controller: ctl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: label,
                suffixIcon: helpTopic == null
                    ? null
                    : HelpBadge(topic: helpTopic, size: 16),
              ),
              onChanged: (_) {
                if (result != null || error != null) {
                  setState(() {
                    result = null;
                    total = null;
                    error = null;
                  });
                }
              }));
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          const Expanded(
              child: Text('ماشین حساب و تبدیل واحد',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
          IconButton(
              tooltip: 'منابع فرمول‌ها',
              onPressed: () => showCalculationSources(context),
              icon: const Icon(Icons.menu_book_outlined))
        ]),
        const Text('محاسبه وزن، متراژ، شاخه، بندیل، سبک/سنگین و خدمات برش و خم',
            style: TextStyle(fontSize: 12, color: muted)),
        Text(
            'شهر سراسری: ${widget.city.isEmpty ? 'همه شهرها' : widget.city}؛ این ماشین حساب از ورودی دستی استفاده می‌کند، نه قیمت شهر دیگر.',
            style: const TextStyle(fontSize: 11, color: muted)),
        const SizedBox(height: 14),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text('تبدیل واحد و خدمات'),
            ),
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.calculate_outlined, size: 18),
              label: Text('فرمولی کلاسیک'),
            ),
          ],
          selected: {converterMode},
          onSelectionChanged: (s) => setState(() => converterMode = s.first),
        ),
        const SizedBox(height: 16),
        if (converterMode) ...[
          const ProductConverterView(),
        ] else ...[
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('حالت پیشرفته'),
            subtitle: const Text('چگالی، تبدیل واحد، مالیات و روش‌های تخصصی'),
            value: advanced,
            onChanged: (v) => setState(() {
                  advanced = v;
                  cutByCount = false;
                  shape = 'round';
                  inputUnit = v ? 'm' : 'piece';
                  quantity.text = '۱';
                  length.text = '۱۲';
                  priceUnit = 'kg';
                  resetFields();
                })),
        if (!advanced) ...[
          const Text('۱. چه کالایی داری؟',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          selectField(
              'نوع کالا',
              shape,
              {
                'round': 'میلگرد',
                'plate': 'ورق',
                'flat': 'تسمه فولادی',
                'anchor': 'بولت / انکربولت خام — نظری',
                'anchorMeasured': 'انکر / ست کامل — وزن واقعی',
                'rhs': 'قوطی / پروفیل',
                'pipe': 'لوله',
                'catalog': 'تیرآهن، نبشی یا ناودانی — با وزن فروشنده'
              },
              (v) => setState(() {
                    shape = v;
                    quantity.text = '۱';
                    length.text = v.startsWith('anchor')
                        ? '۰٫۵'
                        : v == 'plate'
                            ? '۲'
                            : v == 'round' || v == 'catalog'
                                ? '۱۲'
                                : '۶';
                    resetFields();
                  }),
              helpTopic: _helpTopicForShape(shape)),
          const SizedBox(height: 16),
          const Text('۲. اندازه و تعداد را وارد کن',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (['flat', 'anchor', 'anchorMeasured'].contains(shape))
            infoBox('شرایط تخصصی کالا', spec.note),
          if (shape == 'catalog')
            infoBox('وزن را از فروشنده بپرس',
                'برای هر سایز و کارخانه وزن جداست. وزن یک شاخه را از فروشنده یا فاکتور بگیر؛ نمره تیرآهن به‌تنهایی وزن دقیق را مشخص نمی‌کند.'),
          for (final f in spec.fields.where((f) => f.key != 'coat'))
            numeric(
                shape == 'plate' && f.key == 'b'
                    ? 'عرض ورق به متر — مثلاً ۱'
                    : shape == 'catalog' && f.key == 'kgm'
                        ? 'وزن یک شاخه طبق فروشنده (کیلوگرم)'
                        : f.label,
                values[f.key]!,
                helpTopic: _helpTopicForShape(shape)),
          if (shape != 'anchorMeasured')
            numeric(
                shape == 'anchor'
                    ? 'طول بازشده هر بولت روی محور میله (متر)'
                    : shape == 'plate'
                        ? (cutByCount
                            ? 'طول شیت فابریک به متر — مثلاً ۲ یا ۲٫۵'
                            : 'طول ورق به متر — مثلاً ۲')
                        : (cutByCount
                            ? 'طول شاخه فابریک به متر — مثلاً ۶ یا ۱۲'
                            : 'طول یک شاخه به متر — طول واقعی'),
                length),
          if (SteelCalculator.cuttableShapes.contains(shape)) ...[
            const Text('مبنای تعداد (شیت/شاخه کامل یا عدد برش‌خورده)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: false,
                  label: Text(shape == 'plate'
                      ? 'برگ (شیت کامل)'
                      : 'شاخه کامل'),
                ),
                const ButtonSegment<bool>(
                  value: true,
                  label: Text('عدد (برش‌خورده)'),
                ),
              ],
              selected: {cutByCount},
              onSelectionChanged: (s) => setState(() {
                cutByCount = s.first;
                if (!cutByCount && priceUnit == 'cut') priceUnit = 'kg';
                result = null;
                total = null;
                error = null;
              }),
            ),
            const SizedBox(height: 12),
            if (cutByCount) ...[
              infoBox('معیارهای برش «عدد»',
                  shape == 'plate'
                      ? 'ابعاد قطعه برش‌خورده به میلی‌متر را وارد کنید تا هم وزن X عدد و هم تعداد شیت کامل لازم و پرت محاسبه شود.'
                      : 'طول هر عدد برش‌خورده (میلی‌متر) را وارد کنید تا هم وزن X عدد و هم تعداد شاخه کامل لازم و پرت محاسبه شود.'),
              if (shape == 'plate')
                numeric('عرض هر عدد برش‌خورده (میلی‌متر)', cutWidth),
              numeric('طول هر عدد برش‌خورده (میلی‌متر)', cutLength),
            ],
          ],
          numeric(
              shape.startsWith('anchor')
                  ? 'تعداد بولت / انکر / ست کامل'
                  : cutByCount
                      ? 'تعداد قطعات برش‌خورده (چند عدد؟)'
                      : shape == 'plate'
                          ? 'چند برگ ورق می‌خواهی؟'
                          : 'چند شاخه می‌خواهی؟',
              quantity),
          infoBox(
              'واحدها روشن‌اند',
              cutByCount
                  ? 'تعداد قطعات برش‌خورده (عدد) باید صحیح باشد؛ ابعاد برش به میلی‌متر و ابعاد شیت/شاخه فابریک برای محاسبه تعداد شیت/شاخه کامل لازم و پرت استفاده می‌شوند.'
                  : shape == 'plate'
                      ? 'عرض و طول را به متر و ضخامت را به میلی‌متر وارد کن. نمونه: عرض ۱، طول ۲، ضخامت ۲، تعداد ۱ → ۳۱٫۴ کیلوگرم.'
                      : shape.startsWith('anchor')
                          ? 'تعداد، عدد صحیح است؛ وزن بر حسب کیلوگرم. در روش نظری، طول بازشده بر حسب متر است. نرخ هر عدد با هر کیلو فقط با وزن معتبر همان کالا قابل مقایسه است.'
                          : 'اندازه مقطع به میلی‌متر است. طول شاخه به متر و تعداد، عدد صحیح است. نتیجه، وزن مجموع شاخه‌هاست.'),
          ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('۳. هزینه هم حساب شود؟ (اختیاری)'),
              children: [
                numeric('قیمت گفته‌شده فروشنده (تومان؛ خالی = فقط وزن)', price),
                selectField(
                    'این قیمت برای چیست؟',
                    priceUnit,
                    {
                      'kg': 'هر کیلوگرم',
                      if (cutByCount) 'cut': 'هر عدد (برش‌خورده)',
                      'piece': shape.startsWith('anchor')
                          ? 'هر عدد / ست کامل'
                          : shape == 'plate'
                              ? 'هر برگ ورق'
                              : 'هر شاخه'
                    },
                    (v) => setState(() {
                          priceUnit = v;
                          result = null;
                          total = null;
                        })),
                infoBox('هزینه اولیه کالا',
                    'در حالت ساده، حمل و مالیات اضافه محاسبه نمی‌شود. برای این هزینه‌ها حالت پیشرفته را روشن کن.'),
              ]),
        ] else ...[
          selectField(
              'کالا / روش محاسبه',
              shape,
              {for (final s in shapes) s.id: s.label},
              (v) => setState(() {
                    shape = v;
                    if (v.startsWith('anchor')) length.text = '۰٫۵';
                    inputUnit = v == 'bulk'
                        ? 'kg'
                        : v == 'piece' || v == 'mesh' || v.startsWith('anchor')
                            ? 'piece'
                            : 'm';
                    resetFields();
                  }),
              helpTopic: _helpTopicForShape(shape)),
          infoBox('مبنای محاسبه', spec.note),
          const SizedBox(height: 10),
          selectField(
              'جنس و چگالی',
              metal,
              {
                'steel': 'فولاد کربنی — ۷۸۵۰ kg/m³',
                'custom': 'چگالی سفارشی از دیتاشیت جنس'
              },
              (v) => setState(() {
                    metal = v;
                    if (v == 'steel') density.text = '۷۸۵۰';
                    result = null;
                    total = null;
                  }),
              helpTopic: 'density'),
          const SizedBox(height: 14),
          numeric('چگالی (کیلوگرم بر مترمکعب)', density, helpTopic: 'density'),
          for (final f in spec.fields)
            numeric(f.label, values[f.key]!,
                helpTopic: _helpTopicForShape(shape)),
          selectField(
              'واحد مقدار ورودی',
              inputUnit,
              {
                'kg': 'کیلوگرم',
                'm': 'متر طول',
                'piece': 'تعداد برگ (شیت) / شاخه',
                if (SteelCalculator.cuttableShapes.contains(shape))
                  'cut': 'عدد (قطعه برش‌خورده با معیار مشخص)',
                'm2': 'مترمربع مفید'
              },
              (v) => setState(() {
                    inputUnit = v;
                    if (v != 'cut' && priceUnit == 'cut') priceUnit = 'kg';
                    result = null;
                    total = null;
                  }),
              helpTopic: 'order_qty'),
          const SizedBox(height: 14),
          if (inputUnit == 'cut' &&
              SteelCalculator.cuttableShapes.contains(shape)) ...[
            if (shape == 'plate')
              numeric('عرض هر عدد برش‌خورده (میلی‌متر)', cutWidth),
            numeric('طول هر عدد برش‌خورده (میلی‌متر)', cutLength),
          ],
          numeric(
              inputUnit == 'cut'
                  ? 'تعداد قطعات برش‌خورده (عدد)'
                  : 'مقدار مورد نیاز',
              quantity),
          if (!['bulk', 'mesh', 'piece', 'anchorMeasured'].contains(shape))
            numeric(
                shape == 'anchor'
                    ? 'طول بازشده هر بولت روی محور میله (متر)'
                    : inputUnit == 'cut'
                        ? 'طول هر شاخه / برگ فابریک (متر)'
                        : 'طول هر شاخه / قطعه (متر)',
                length),
          numeric('پرت یا اضافه سفارش (%)', waste),
          const Divider(height: 30),
          const Text('برآورد هزینه — اختیاری',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          numeric('قیمت واحد (تومان؛ خالی = فقط وزن)', price),
          selectField(
              'واحد قیمت',
              priceUnit,
              {
                'kg': 'تومان / کیلوگرم',
                'ton': 'تومان / تن',
                'm': 'تومان / متر',
                'piece': 'تومان / شاخه یا برگ (شیت)',
                if (inputUnit == 'cut') 'cut': 'تومان / عدد (برش‌خورده)',
                'm2': 'تومان / مترمربع'
              },
              (v) => setState(() {
                    priceUnit = v;
                    result = null;
                    total = null;
                  })),
          const SizedBox(height: 14),
          numeric('مالیات اضافه بر قیمت ورودی (%)', tax),
          numeric('حمل کل سفارش (تومان)', shipping),
          numeric('خدمات کل سفارش (تومان؛ نهایی با مالیات)', services),
        ],
        FilledButton.icon(
            onPressed: calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Padding(
                padding: EdgeInsets.all(12), child: Text('محاسبه'))),
        if (error != null)
          infoBox('ورودی نیازمند اصلاح است', error!, color: Colors.red),
        if (result != null) ...[
          const SizedBox(height: 20),
          Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: ink, borderRadius: BorderRadius.circular(18)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('وزن کل برآوردی',
                        style: TextStyle(color: Colors.white70)),
                    Text('${fmt(result!.kg, decimals: 3)} کیلوگرم',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 26)),
                    const SizedBox(height: 18),
                    if (result!.metres > 0)
                      Text('متراژ: ${fmt(result!.metres, decimals: 3)} متر',
                          style: const TextStyle(color: Colors.white70)),
                    if (result!.area > 0)
                      Text(
                          'مساحت مفید: ${fmt(result!.area, decimals: 3)} مترمربع',
                          style: const TextStyle(color: Colors.white70)),
                    if (result!.pieces > 0)
                      Text(
                          result!.cutAllocation != null
                              ? 'تعداد برش‌خورده: ${fmt(result!.pieces, decimals: 0)} عدد • وزن هر عدد: ${fmt(result!.cutAllocation!.kgPerCut, decimals: 3)} کیلوگرم'
                              : 'تعداد معادل: ${fmt(result!.pieces, decimals: 3)} • برای خرید قطعه کامل: ${fmt(result!.pieces.ceil())}',
                          style: const TextStyle(color: Colors.white70)),
                    if (result!.cutAllocation != null) ...[
                      const Divider(color: Colors.white24, height: 24),
                      if (result!.cutAllocation!.fitsInStock) ...[
                        Text(
                          'تأمین از ${result!.cutAllocation!.isSheet ? 'شیت' : 'شاخه'} فابریک: '
                          '${fmt(result!.cutAllocation!.requiredStockPieces)} '
                          '${result!.cutAllocation!.isSheet ? 'برگ (شیت کامل)' : 'شاخه کامل'} '
                          '(هر ${result!.cutAllocation!.isSheet ? 'شیت' : 'شاخه'}: ${fmt(result!.cutAllocation!.cutsPerStockPiece)} عدد)',
                          style: const TextStyle(
                              color: Color(0xff62e0ce),
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'وزن کل ${result!.cutAllocation!.isSheet ? 'شیت‌های' : 'شاخه‌های'} مصرفی: '
                          '${fmt(result!.cutAllocation!.stockTotalKg, decimals: 3)} کیلوگرم',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'پرت / باقیمانده برش: ${fmt(result!.cutAllocation!.wasteKg, decimals: 3)} کیلوگرم '
                          '(${fmt(result!.cutAllocation!.wastePercent, decimals: 1)}٪)'
                          '${result!.cutAllocation!.isSheet ? ' • ${fmt(result!.cutAllocation!.wasteAreaM2, decimals: 3)} مترمربع' : ' • ${fmt(result!.cutAllocation!.wasteLengthM, decimals: 2)} متر'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ] else
                        const Text(
                          'هشدار: ابعاد قطعه برش‌خورده از یک شیت/شاخه فابریک بزرگ‌تر است.',
                          style: TextStyle(color: Colors.amberAccent),
                        ),
                    ],
                    if (total != null) ...[
                      const Divider(color: Colors.white24, height: 28),
                      const Text('هزینه برآوردی',
                          style: TextStyle(color: Colors.white70)),
                      Text('${fmt(total)} تومان',
                          style: const TextStyle(
                              color: Color(0xff62e0ce),
                              fontWeight: FontWeight.bold,
                              fontSize: 24)),
                      Text(moneyWords(total!),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12))
                    ]
                  ])),
          infoBox('وزن نظری، نه وزن قطعی بار',
              'پرت در خروجی لحاظ شده است. تعداد معادل ممکن است کسری باشد؛ گردکردن تعداد برای خرید، هزینه را خودکار تغییر نمی‌دهد. برای قطعه کامل دوباره با تعداد گرد‌شده محاسبه کنید. مالیات فقط بر مبلغ کالا افزوده می‌شود؛ حمل و خدمات، هزینه نهایی ورودی‌اند.'),
        ],
        infoBox('گرید و پوشش',
            'برای استیل، آلومینیوم و آلیاژ خاص، چگالی از دیتاشیت همان گرید وارد شود. وزن هندسی، جای گواهی سازنده، باسکول یا طراحی سازه را نمی‌گیرد.'),
        ],
      ]);
}

Future<void> showCalculationSources(BuildContext context) async {
  final list =
      jsonDecode(await rootBundle.loadString('assets/calculation_sources.json'))
          as List;
  if (!context.mounted) return;
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .8,
          child: ListView(padding: const EdgeInsets.all(22), children: [
            const Text('فرمول‌ها و منابع',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            infoBox('قاعده پایه',
                'جرم = چگالی × حجم. ابعاد مقطع به میلی‌متر، طول به متر و چگالی به kg/m³ هستند؛ وزن خروجی کیلوگرم است.'),
            for (final x in list)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(x['title'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Directionality(
                                textDirection: TextDirection.ltr,
                                child: SelectableText(x['formula'],
                                    style: const TextStyle(fontSize: 12))),
                            const SizedBox(height: 8),
                            Text(x['note'],
                                style:
                                    const TextStyle(fontSize: 12, height: 1.8)),
                            for (final u in x['sources'])
                              TextButton.icon(
                                  onPressed: () => openLink(ctx, u),
                                  icon: const Icon(Icons.link, size: 16),
                                  label: Text(Uri.parse(u).host))
                          ])))
          ])));
}
