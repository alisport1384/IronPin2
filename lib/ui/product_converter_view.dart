import 'package:flutter/material.dart';
import '../domain/market.dart';
import '../domain/money.dart';
import '../domain/product_converter.dart';
import 'common.dart';

class ProductConverterView extends StatefulWidget {
  const ProductConverterView({super.key});

  @override
  State<ProductConverterView> createState() => _ProductConverterViewState();
}

class _ProductConverterViewState extends State<ProductConverterView> {
  String productId = 'plate';
  String alloyId = 'steel';
  String inputUnit = 'm';
  String priceUnit = 'kg';

  final fieldCtls = <String, TextEditingController>{};
  final densityCtl = TextEditingController(text: '۷۸۵۰');
  final inputValueCtl = TextEditingController(text: '۱۰');
  final unitPriceCtl = TextEditingController();
  final cutWidthCtl = TextEditingController(text: '۳۰۰');
  final cutLengthCtl = TextEditingController(text: '۴۰۰');
  bool showCutFields = false;

  ConverterProductSpec get spec =>
      converterProducts.firstWhere((p) => p.id == productId);

  MetalAlloy get alloy =>
      metalAlloys.firstWhere((a) => a.id == alloyId);

  @override
  void initState() {
    super.initState();
    _initFieldsForProduct();
  }

  void _initFieldsForProduct() {
    for (final c in fieldCtls.values) {
      c.dispose();
    }
    fieldCtls.clear();
    for (final f in spec.fields) {
      fieldCtls[f.key] =
          TextEditingController(text: fmt(f.initial, decimals: f.integerOnly ? 0 : 2));
    }
    cutWidthCtl.text = '۳۰۰';
    cutLengthCtl.text = productId == 'plate' ? '۴۰۰' : '۱۵۰۰';
    if (!spec.supportedUnits.contains(inputUnit)) {
      inputUnit = spec.supportedUnits.first;
    }
    if (!spec.supportedUnits.contains(priceUnit)) {
      priceUnit = 'kg';
    }
    if (!spec.supportsCutCount) {
      showCutFields = false;
    }
  }

  @override
  void dispose() {
    for (final c in [
      ...fieldCtls.values,
      densityCtl,
      inputValueCtl,
      unitPriceCtl,
      cutWidthCtl,
      cutLengthCtl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  ({ProductConversionResult? result, String? error}) _evaluate() {
    try {
      final d = spec.usesDensity
          ? (alloyId == 'custom'
              ? (number(densityCtl.text) ?? -1)
              : alloy.density)
          : 7850.0;
      final fields = <String, double>{};
      for (final f in spec.fields) {
        final v = number(fieldCtls[f.key]!.text);
        if (v == null) {
          return (
            result: null,
            error: '${f.label}: عدد معتبر وارد کنید.',
          );
        }
        fields[f.key] = v;
      }
      final q = number(inputValueCtl.text);
      if (q == null) {
        return (result: null, error: 'مقدار تبدیل را وارد کنید.');
      }
      final cutActive = spec.supportsCutCount &&
          (inputUnit == 'cut' || priceUnit == 'cut' || showCutFields);
      double? cutLenMm;
      double? cutWidMm;
      if (cutActive) {
        cutLenMm = number(cutLengthCtl.text);
        if (cutLenMm == null) {
          return (
            result: null,
            error: 'طول هر عدد برش‌خورده (میلی‌متر) را وارد کنید.',
          );
        }
        if (productId == 'plate') {
          cutWidMm = number(cutWidthCtl.text);
          if (cutWidMm == null) {
            return (
              result: null,
              error: 'عرض هر عدد برش‌خورده (میلی‌متر) را وارد کنید.',
            );
          }
        }
      }
      final res = ProductConverter.convert(
        productId: productId,
        fields: fields,
        density: d,
        inputUnit: inputUnit,
        inputValue: q,
        cutLengthMm: cutLenMm,
        cutWidthMm: cutWidMm,
      );
      return (result: res, error: null);
    } on FormatException catch (e) {
      return (result: null, error: e.message);
    } catch (_) {
      return (result: null, error: 'مقادیر ورودی معتبر نیستند.');
    }
  }

  Widget _numField(String label, TextEditingController ctl) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final eval = _evaluate();
    final res = eval.result;
    final unitOptions = {
      for (final u in spec.supportedUnits)
        u: ProductConverter.unitLabel(spec, u),
    };
    final priceOptions = {
      for (final u in spec.supportedUnits)
        u: 'هر ${ProductConverter.unitLabel(spec, u)}',
    };

    final enteredPrice = number(unitPriceCtl.text);
    double? totalCost;
    if (res != null && enteredPrice != null && enteredPrice > 0) {
      final unitAmount = switch (priceUnit) {
        'm' => res.totalMetres,
        'm2' => res.totalAreaM2,
        'kg' => res.totalKg,
        'ton' => res.totalTon,
        'piece' => res.totalPieces,
        'cut' => res.totalCuts,
        'bundle' => res.totalBundles,
        _ => 0.0,
      };
      if (unitAmount > 0) {
        totalCost = unitAmount * enteredPrice;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('۱. انتخاب کالا و مشخصات اختصاصی',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        selectField(
          'کالای آهن‌آلات',
          productId,
          {for (final p in converterProducts) p.id: p.title},
          (v) => setState(() {
            productId = v;
            _initFieldsForProduct();
          }),
        ),
        const SizedBox(height: 6),
        infoBox('مشخصات این کالا: ${spec.subtitle}', spec.note),
        if (spec.usesDensity) ...[
          const SizedBox(height: 8),
          selectField(
            'جنس / آلیاژ',
            alloyId,
            {for (final a in metalAlloys) a.id: '${a.label} (${fmt(a.density)} kg/m³)'},
            (v) => setState(() {
              alloyId = v;
              if (v != 'custom') {
                densityCtl.text = fmt(alloy.density);
              }
            }),
          ),
          const SizedBox(height: 12),
          if (alloyId == 'custom')
            _numField('چگالی سفارشی جنس (کیلوگرم بر مترمکعب)', densityCtl),
        ],
        const SizedBox(height: 4),
        for (final f in spec.fields) _numField(f.label, fieldCtls[f.key]!),
        if (spec.supportsCutCount) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('معیارهای برش «عدد» (قطعه برش‌خورده)'),
            subtitle: Text(
                productId == 'plate'
                    ? 'عرض و طول قطعه برش‌خورده برای تفکیک «عدد» از «برگ (شیت)»'
                    : 'طول قطعه برش‌خورده برای تفکیک «عدد» از «شاخه»'),
            value: inputUnit == 'cut' || priceUnit == 'cut' || showCutFields,
            onChanged: (v) => setState(() {
              showCutFields = v;
              if (!v) {
                if (inputUnit == 'cut') inputUnit = spec.supportedUnits.first;
                if (priceUnit == 'cut') priceUnit = 'kg';
              }
            }),
          ),
          if (inputUnit == 'cut' || priceUnit == 'cut' || showCutFields) ...[
            if (productId == 'plate')
              _numField('عرض هر عدد برش‌خورده (میلی‌متر)', cutWidthCtl),
            _numField(
                productId == 'plate'
                    ? 'طول هر عدد برش‌خورده (میلی‌متر)'
                    : 'طول هر عدد برش‌خورده (میلی‌متر؛ مثلاً ۱۵۰۰ = ۱٫۵ متر)',
                cutLengthCtl),
          ],
        ],
        const Divider(height: 24),
        const Text('۲. مقدار و واحد مبدأ برای تبدیل',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _numField('مقدار ورودی', inputValueCtl),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: selectField(
                'واحد ورودی',
                inputUnit,
                unitOptions,
                (v) => setState(() => inputUnit = v),
              ),
            ),
          ],
        ),
        if (eval.error != null)
          infoBox('نیازمند اصلاح ورودی', eval.error!, color: Colors.red),
        if (res != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معادل تبدیل برای ${spec.title}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                _ResultLine(
                  label: 'وزن کل (کیلوگرم)',
                  value: '${fmt(res.totalKg, decimals: 3)} کیلوگرم',
                  highlight: true,
                ),
                _ResultLine(
                  label: 'تناژ (تن)',
                  value: '${fmt(res.totalTon, decimals: 4)} تن',
                ),
                if (spec.hasMetres)
                  _ResultLine(
                    label: 'متراژ طولی',
                    value: '${fmt(res.totalMetres, decimals: 3)} متر',
                  ),
                if (spec.hasArea)
                  _ResultLine(
                    label: 'مساحت کل',
                    value: '${fmt(res.totalAreaM2, decimals: 3)} مترمربع',
                  ),
                _ResultLine(
                  label:
                      'تعداد (${ProductConverter.unitLabel(spec, 'piece')})',
                  value:
                      '${fmt(res.totalPieces, decimals: 2)} ${ProductConverter.unitLabel(spec, 'piece')} (خرید کامل: ${fmt(res.totalPieces.ceil())})',
                ),
                if (res.cutAllocation != null) ...[
                  _ResultLine(
                    label: 'تعداد برش‌خورده (عدد)',
                    value:
                        '${fmt(res.totalCuts, decimals: 2)} عدد (هر عدد: ${fmt(res.kgPerCut, decimals: 3)} کیلو)',
                  ),
                  if (res.cutAllocation!.fitsInStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'تأمین از ${res.cutAllocation!.isSheet ? 'شیت' : 'شاخه'} فابریک: '
                        '${fmt(res.cutAllocation!.requiredStockPieces)} ${spec.pieceLabel} '
                        '(هر ${res.cutAllocation!.isSheet ? 'شیت' : 'شاخه'}: ${fmt(res.cutAllocation!.cutsPerStockPiece)} عدد) • '
                        'پرت: ${fmt(res.cutAllocation!.wasteKg, decimals: 2)} کیلو (${fmt(res.cutAllocation!.wastePercent, decimals: 1)}٪)',
                        style: const TextStyle(
                          color: Color(0xff62e0ce),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'ابعاد برش از یک شیت/شاخه فابریک بزرگ‌تر است.',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                      ),
                    ),
                ],
                _ResultLine(
                  label: 'تعداد ${spec.bundleLabel}',
                  value:
                      '${fmt(res.totalBundles, decimals: 3)} ${spec.bundleLabel}',
                ),
                if (res.bundleBreakdown.wholeBundles > 0 ||
                    res.bundleBreakdown.remainingPieces > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'بسته‌بندی دقیق: ${fmt(res.bundleBreakdown.wholeBundles)} ${spec.bundleLabel}'
                      '${res.bundleBreakdown.remainingPieces > 0.001 ? ' + ${fmt(res.bundleBreakdown.remainingPieces, decimals: 2)} ${spec.pieceLabel}' : ''}',
                      style: const TextStyle(
                        color: Color(0xff62e0ce),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Divider(color: Colors.white24, height: 22),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (res.kgPerMetre > 0)
                      Text(
                        'هر متر: ${fmt(res.kgPerMetre, decimals: 3)} کیلو',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    Text(
                      'هر ${ProductConverter.unitLabel(spec, 'piece')}: ${fmt(res.kgPerPiece, decimals: 3)} کیلو',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      'هر ${spec.bundleLabel}: ${fmt(res.kgPerBundle, decimals: 2)} کیلو',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('۳. تبدیل قیمت بین واحدهای این کالا (اختیاری)'),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _numField('قیمت (تومان)', unitPriceCtl),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: selectField(
                      'مبنای این قیمت',
                      priceUnit,
                      priceOptions,
                      (v) => setState(() => priceUnit = v),
                    ),
                  ),
                ],
              ),
              if (totalCost != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(.08),
                    border: Border.all(color: teal.withOpacity(.25)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مبلغ کل سفارش',
                          style: TextStyle(fontSize: 12, color: muted)),
                      Text(
                        '${fmt(totalCost)} تومان',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ink),
                      ),
                      Text(moneyWords(totalCost),
                          style: const TextStyle(fontSize: 11, color: muted)),
                      const Divider(height: 18),
                      const Text('نرخ معادل همین قیمت در سایر واحدها:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                          '• هر کیلوگرم: ${fmt(totalCost / res.totalKg)} تومان'),
                      Text(
                          '• هر تن: ${fmt(totalCost / res.totalTon)} تومان'),
                      if (spec.hasMetres && res.totalMetres > 0)
                        Text(
                            '• هر متر: ${fmt(totalCost / res.totalMetres)} تومان'),
                      if (spec.hasArea && res.totalAreaM2 > 0)
                        Text(
                            '• هر مترمربع: ${fmt(totalCost / res.totalAreaM2)} تومان'),
                      Text(
                          '• هر ${ProductConverter.unitLabel(spec, 'piece')}: ${fmt(totalCost / res.totalPieces)} تومان'),
                      if (res.totalCuts > 0)
                        Text(
                            '• هر عدد (برش‌خورده): ${fmt(totalCost / res.totalCuts)} تومان'),
                      Text(
                          '• هر ${spec.bundleLabel}: ${fmt(totalCost / res.totalBundles)} تومان'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ResultLine extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _ResultLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: highlight ? Colors.white : Colors.white70,
                    fontSize: highlight ? 13 : 12)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: highlight ? const Color(0xff62e0ce) : Colors.white,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                  fontSize: highlight ? 18 : 13,
                ),
              ),
            ),
          ],
        ),
      );
}
