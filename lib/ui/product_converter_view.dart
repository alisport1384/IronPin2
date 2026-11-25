import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/market.dart';
import '../domain/market_tables.dart';
import '../domain/money.dart';
import '../domain/product_converter.dart';
import 'common.dart';
import 'visual_help.dart';

class _ServiceDraft {
  final int id;
  final TextEditingController nameCtl;
  final TextEditingController qtyCtl;
  final TextEditingController priceCtl;
  String unit;
  bool autoFromProduct;

  _ServiceDraft({
    required this.id,
    required String name,
    required this.unit,
    bool? autoFromProduct,
    String initialQty = '۱',
    String initialPrice = '',
  })  : autoFromProduct =
            autoFromProduct ?? (unit != 'manual' && unit != 'flat'),
        nameCtl = TextEditingController(text: name),
        qtyCtl = TextEditingController(text: initialQty),
        priceCtl = TextEditingController(text: initialPrice);

  void dispose() {
    nameCtl.dispose();
    qtyCtl.dispose();
    priceCtl.dispose();
  }
}

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

  // Market preset (سبک / سنگین / جدول بازار)
  bool usePreset = false;
  bool useHeavyPreset = false;
  String? presetId;

  // Dimension unit helper for manual plate / cut_plate / flat / channel
  bool manualDimensionsInCm = false;

  final fieldCtls = <String, TextEditingController>{};
  final densityCtl = TextEditingController(text: '۷۸۵۰');
  final inputValueCtl = TextEditingController(text: '۱۰');
  final unitPriceCtl = TextEditingController();
  final shippingCtl = TextEditingController(text: '۰');
  final taxPctCtl = TextEditingController(text: '۰');
  final cutWidthCtl = TextEditingController(text: '۳۰۰');
  final cutLengthCtl = TextEditingController(text: '۴۰۰');
  bool showCutFields = false;
  bool taxIncludesServices = true;

  int _nextServiceId = 1;
  final List<_ServiceDraft> _services = [];

  ConverterProductSpec get spec =>
      converterProducts.firstWhere((p) => p.id == productId);

  MetalAlloy get alloy =>
      metalAlloys.firstWhere((a) => a.id == alloyId);

  MarketPresetGroup? get presetGroup => marketPresetGroups[productId];

  List<MarketPresetItem> get activePresetItems {
    final g = presetGroup;
    if (g == null) return const [];
    if (useHeavyPreset && g.heavyItems.isNotEmpty) return g.heavyItems;
    return g.lightItems;
  }

  MarketPresetItem? get selectedPreset {
    final items = activePresetItems;
    if (!usePreset || items.isEmpty) return null;
    for (final it in items) {
      if (it.id == presetId) return it;
    }
    return items.first;
  }

  bool get supportsCmDimensions =>
      const {'plate', 'cut_plate', 'flat', 'channel', 'wallpost', 'gutter'}
          .contains(productId);

  bool _isCmScaledField(String key) {
    if (!manualDimensionsInCm) return false;
    return switch (productId) {
      'plate' || 'wallpost' || 'gutter' => key == 'widthMm',
      'cut_plate' => key == 'widthMm' || key == 'lengthMm',
      'flat' => key == 'widthMm',
      'channel' => key == 'heightMm' || key == 'widthMm',
      _ => false,
    };
  }

  String _fieldLabel(ConverterField f) {
    if (_isCmScaledField(f.key)) {
      return f.label.replaceAll('میلی‌متر', 'سانتی‌متر');
    }
    return f.label;
  }

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
    manualDimensionsInCm = false;
    for (final f in spec.fields) {
      fieldCtls[f.key] = TextEditingController(
          text: fmt(f.initial, decimals: f.integerOnly ? 0 : 2));
    }
    final g = presetGroup;
    useHeavyPreset = false;
    usePreset = g != null &&
        const {'beam', 'hbeam', 'stud', 'mesh_area'}.contains(productId);
    presetId = g != null && g.lightItems.isNotEmpty ? g.lightItems.first.id : null;
    if (usePreset && selectedPreset != null) {
      _applyPresetValues(selectedPreset!);
    }
    cutWidthCtl.text = '۳۰۰';
    cutLengthCtl.text = productId == 'plate' ? '۴۰۰' : '۱۵۰۰';
    if (!spec.supportedUnits.contains(inputUnit)) {
      inputUnit = productId == 'mesh_area'
          ? 'm2'
          : (spec.supportedUnits.contains('piece')
              ? 'piece'
              : spec.supportedUnits.first);
    }
    if (!spec.supportedUnits.contains(priceUnit)) {
      priceUnit = 'kg';
    }
    if (!spec.supportsCutCount) {
      showCutFields = false;
    }
  }

  void _applyPresetValues(MarketPresetItem item) {
    if (item.defaultPieceLengthM != null &&
        fieldCtls.containsKey('pieceLengthM')) {
      fieldCtls['pieceLengthM']!.text = fmt(item.defaultPieceLengthM!, decimals: 2);
    }
    if (item.kgPerMetre != null && fieldCtls.containsKey('kgPerMetre')) {
      fieldCtls['kgPerMetre']!.text = fmt(item.kgPerMetre!, decimals: 3);
    }
    if (item.kgPerMetre != null && fieldCtls.containsKey('kgPerM2')) {
      fieldCtls['kgPerM2']!.text = fmt(item.kgPerMetre!, decimals: 2);
    }
  }

  void _toggleCmMode(bool toCm) {
    if (toCm == manualDimensionsInCm) return;
    final factor = toCm ? 0.1 : 10.0;
    for (final f in spec.fields) {
      final wasScaled = manualDimensionsInCm &&
          switch (productId) {
            'plate' || 'wallpost' || 'gutter' => f.key == 'widthMm',
            'cut_plate' => f.key == 'widthMm' || f.key == 'lengthMm',
            'flat' => f.key == 'widthMm',
            'channel' => f.key == 'heightMm' || f.key == 'widthMm',
            _ => false,
          };
      final willScale = toCm &&
          switch (productId) {
            'plate' || 'wallpost' || 'gutter' => f.key == 'widthMm',
            'cut_plate' => f.key == 'widthMm' || f.key == 'lengthMm',
            'flat' => f.key == 'widthMm',
            'channel' => f.key == 'heightMm' || f.key == 'widthMm',
            _ => false,
          };
      if (wasScaled != willScale) {
        final v = number(fieldCtls[f.key]!.text);
        if (v != null) {
          fieldCtls[f.key]!.text = fmt(v * factor, decimals: 3);
        }
      }
    }
    manualDimensionsInCm = toCm;
  }

  void _addService(String name, String defaultUnit) {
    setState(() {
      _services.add(_ServiceDraft(
        id: _nextServiceId++,
        name: name,
        unit: defaultUnit,
        autoFromProduct: defaultUnit != 'manual' && defaultUnit != 'flat',
      ));
    });
  }

  @override
  void dispose() {
    for (final c in [
      ...fieldCtls.values,
      densityCtl,
      inputValueCtl,
      unitPriceCtl,
      shippingCtl,
      taxPctCtl,
      cutWidthCtl,
      cutLengthCtl,
    ]) {
      c.dispose();
    }
    for (final s in _services) {
      s.dispose();
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
        final raw = number(fieldCtls[f.key]!.text);
        if (raw == null) {
          return (
            result: null,
            error: '${_fieldLabel(f)}: عدد معتبر وارد کنید.',
          );
        }
        fields[f.key] = _isCmScaledField(f.key) ? raw * 10.0 : raw;
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
      final preset = selectedPreset;
      final res = ProductConverter.convert(
        productId: productId,
        fields: fields,
        density: d,
        inputUnit: inputUnit,
        inputValue: q,
        cutLengthMm: cutLenMm,
        cutWidthMm: cutWidMm,
        overrideKgPerMetre: preset?.kgPerMetre,
        overrideKgPerPiece:
            (preset?.kgPerMetre == null) ? preset?.kgPerPiece : null,
        overrideAreaPerPiece: preset?.areaPerPieceM2,
      );
      return (result: res, error: null);
    } on FormatException catch (e) {
      return (result: null, error: e.message);
    } catch (_) {
      return (result: null, error: 'مقادیر ورودی معتبر نیستند.');
    }
  }

  Widget _numField(String label, TextEditingController ctl,
          {bool enabled = true, String? helpTopic}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctl,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon:
                helpTopic == null ? null : HelpBadge(topic: helpTopic, size: 16),
          ),
          onChanged: (_) => setState(() {}),
        ),
      );

  String _helpTopicForField(String key) => switch (key) {
        'piecesPerBundle' => 'bundle',
        'pieceLengthM' => productId,
        'kgPerM2' || 'areaPerPieceM2' => 'mesh_area',
        _ => productId,
      };

  @override
  Widget build(BuildContext context) {
    final eval = _evaluate();
    final res = eval.result;
    final group = presetGroup;
    final preset = selectedPreset;

    final unitOptions = {
      for (final u in spec.supportedUnits)
        u: ProductConverter.unitLabel(spec, u),
    };
    final priceOptions = {
      for (final u in spec.supportedUnits)
        u: 'هر ${ProductConverter.unitLabel(spec, u)}',
    };
    final serviceUnitOptions = <String, String>{
      'kg': 'هر کیلوگرم',
      'ton': 'هر تن',
      if (spec.hasMetres) 'm': 'هر متر',
      if (spec.hasArea) 'm2': 'هر مترمربع',
      'piece': 'هر ${spec.pieceLabel}',
      if (spec.supportsCutCount) 'cut': 'هر عدد (برش‌خورده)',
      'bundle': 'هر ${spec.bundleLabel}',
      'manual': 'تعداد دلخواه (سوراخ/خم/برش)',
      'flat': 'مبلغ ثابت کل',
    };

    OrderCostResult? orderCost;
    String? costError;
    if (res != null) {
      try {
        final basePrice = unitPriceCtl.text.trim().isEmpty
            ? null
            : number(unitPriceCtl.text);
        if (unitPriceCtl.text.trim().isNotEmpty && basePrice == null) {
          costError = 'قیمت پایه کالا نامعتبر است.';
        } else {
          final ship = shippingCtl.text.trim().isEmpty
              ? 0.0
              : (number(shippingCtl.text) ?? -1);
          final taxP = taxPctCtl.text.trim().isEmpty
              ? 0.0
              : (number(taxPctCtl.text) ?? -1);
          final svcInputs = <OrderServiceInput>[];
          for (final s in _services) {
            final sp = s.priceCtl.text.trim().isEmpty
                ? 0.0
                : (number(s.priceCtl.text) ?? -1);
            double? manualQ;
            if (s.unit == 'manual' || !s.autoFromProduct) {
              manualQ = s.qtyCtl.text.trim().isEmpty
                  ? 0.0
                  : (number(s.qtyCtl.text) ?? -1);
            }
            svcInputs.add(OrderServiceInput(
              name: s.nameCtl.text,
              unit: s.unit,
              manualQuantity: manualQ,
              unitPrice: sp,
            ));
          }
          if ((basePrice != null && basePrice > 0) ||
              svcInputs.any((e) => e.unitPrice > 0) ||
              ship > 0) {
            orderCost = ProductConverter.calculateOrderCost(
              conversion: res,
              basePriceUnit: priceUnit,
              baseUnitPrice: basePrice,
              services: svcInputs,
              shipping: ship,
              taxPercent: taxP,
              taxIncludesServices: taxIncludesServices,
            );
          }
        }
      } on FormatException catch (e) {
        costError = e.message;
      } catch (_) {
        costError = 'مقادیر بخش قیمت یا خدمات معتبر نیست.';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('۱. انتخاب کالا، جدول استاندارد یا ابعاد',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            HelpBadge(topic: productId, size: 17),
          ],
        ),
        const SizedBox(height: 10),
        selectField(
          'کالای آهن‌آلات',
          productId,
          {for (final p in converterProducts) p.id: p.title},
          (v) => setState(() {
            productId = v;
            _initFieldsForProduct();
          }),
          helpTopic: productId,
        ),
        const SizedBox(height: 6),
        infoBox('مشخصات کالا: ${spec.subtitle}', spec.note),
        if (group != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.table_chart_outlined, size: 17),
                      label: Text('جدول بازار (سبک/سنگین)'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.straighten_outlined, size: 17),
                      label: Text('ابعاد / وزن دستی'),
                    ),
                  ],
                  selected: {usePreset},
                  onSelectionChanged: (s) => setState(() {
                    usePreset = s.first;
                    if (usePreset && selectedPreset != null) {
                      _applyPresetValues(selectedPreset!);
                    }
                  }),
                ),
              ),
              const SizedBox(width: 4),
              HelpBadge(
                topic: group.hasLightHeavy ? 'light_heavy' : productId,
                size: 17,
              ),
            ],
          ),
          if (usePreset) ...[
            const SizedBox(height: 10),
            if (group.hasLightHeavy) ...[
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text(group.lightLabel),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text(group.heavyLabel),
                        ),
                      ],
                      selected: {useHeavyPreset},
                      onSelectionChanged: (s) => setState(() {
                        useHeavyPreset = s.first;
                        final items = activePresetItems;
                        if (items.isNotEmpty) {
                          if (!items.any((it) => it.id == presetId)) {
                            presetId = items.first.id;
                          }
                          final cur = selectedPreset;
                          if (cur != null) _applyPresetValues(cur);
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const HelpBadge(topic: 'light_heavy', size: 17),
                ],
              ),
              if (group.lightHeavyReason.isNotEmpty) ...[
                const SizedBox(height: 8),
                infoBox('فرق سبک و سنگین در این کالا چیست؟',
                    group.lightHeavyReason,
                    color: teal),
              ],
            ],
            const SizedBox(height: 8),
            selectField(
              group.variantLabel,
              preset?.id ?? activePresetItems.first.id,
              {for (final it in activePresetItems) it.id: it.label},
              (v) => setState(() {
                presetId = v;
                final cur = selectedPreset;
                if (cur != null) _applyPresetValues(cur);
              }),
              helpTopic: productId,
            ),
          ],
        ],
        if (productId == 'plate') ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ActionChip(
                label: const Text('ورق ۱×۲ متر'),
                onPressed: () => setState(() {
                  manualDimensionsInCm = false;
                  fieldCtls['widthMm']!.text = '۱۰۰۰';
                  fieldCtls['pieceLengthM']!.text = '۲';
                }),
              ),
              ActionChip(
                label: const Text('ورق ۱٫۲۵×۲٫۵ متر'),
                onPressed: () => setState(() {
                  manualDimensionsInCm = false;
                  fieldCtls['widthMm']!.text = '۱۲۵۰';
                  fieldCtls['pieceLengthM']!.text = '۲٫۵';
                }),
              ),
              ActionChip(
                label: const Text('ورق ۱٫۵×۶ متر'),
                onPressed: () => setState(() {
                  manualDimensionsInCm = false;
                  fieldCtls['widthMm']!.text = '۱۵۰۰';
                  fieldCtls['pieceLengthM']!.text = '۶';
                }),
              ),
            ],
          ),
        ],
        if (!usePreset && spec.usesDensity) ...[
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
            helpTopic: 'density',
          ),
          const SizedBox(height: 10),
          if (alloyId == 'custom')
            _numField('چگالی سفارشی جنس (کیلوگرم بر مترمکعب)', densityCtl,
                helpTopic: 'density'),
        ],
        if (!usePreset && supportsCmDimensions) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ورود عرض و طول بر حسب سانتی‌متر'),
            subtitle: const Text('مثلاً ورق یا پلیت ۲۰×۲۰ سانتی‌متر یا ناودانی ۱۰×۲۵ سانتی‌متر'),
            value: manualDimensionsInCm,
            onChanged: (v) => setState(() => _toggleCmMode(v)),
          ),
        ],
        const SizedBox(height: 4),
        for (final f in spec.fields)
          if (!usePreset ||
              f.key == 'pieceLengthM' ||
              f.key == 'piecesPerBundle' ||
              (productId == 'mesh_area' && f.key == 'areaPerPieceM2'))
            _numField(_fieldLabel(f), fieldCtls[f.key]!,
                helpTopic: _helpTopicForField(f.key)),
        if (spec.supportsCutCount) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Row(
              children: [
                Expanded(
                    child: Text('معیارهای برش «عدد» (قطعه برش‌خورده)')),
                HelpBadge(topic: 'cut_piece', size: 16),
              ],
            ),
            subtitle: Text(productId == 'plate'
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
              _numField('عرض هر عدد برش‌خورده (میلی‌متر)', cutWidthCtl,
                  helpTopic: 'cut_piece'),
            _numField(
                productId == 'plate'
                    ? 'طول هر عدد برش‌خورده (میلی‌متر)'
                    : 'طول هر عدد برش‌خورده (میلی‌متر؛ مثلاً ۱۵۰۰ = ۱٫۵ متر)',
                cutLengthCtl,
                helpTopic: 'cut_piece'),
          ],
        ],
        const Divider(height: 24),
        const Row(
          children: [
            Expanded(
              child: Text('۲. مقدار سفارش شما چقدر است؟ (تبدیل به همه واحدها)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            HelpBadge(topic: 'order_qty', size: 17),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'بخش ۱ فقط وزن یک متر/شاخه را می‌سازد؛ اینجا مقدار کل سفارش (مثلاً ۵۰۰ کیلو یا ۱۰ شاخه) را بزنید تا معادل بقیه واحدها حساب شود.',
          style: TextStyle(fontSize: 11, color: muted, height: 1.6),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _numField('مقدار سفارش', inputValueCtl,
                  helpTopic: 'order_qty'),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: selectField(
                'بر حسب واحد',
                inputUnit,
                unitOptions,
                (v) => setState(() => inputUnit = v),
                helpTopic: 'order_qty',
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
                  preset != null
                      ? 'معادل تبدیل: ${spec.title} (${preset.label})'
                      : 'معادل تبدیل برای ${spec.title}',
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
                  label: 'تعداد (${ProductConverter.unitLabel(spec, 'piece')})',
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
          const Divider(height: 28),
          const Row(
            children: [
              Expanded(
                child: Text('۳. قیمت پایه، خدمات جانبی و قیمت نهایی',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              HelpBadge(topic: 'services', size: 17),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _numField('قیمت پایه کالا (تومان)', unitPriceCtl,
                    helpTopic: 'basis'),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: selectField(
                  'مبنای قیمت پایه',
                  priceUnit,
                  priceOptions,
                  (v) => setState(() => priceUnit = v),
                  helpTopic: 'basis',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Expanded(
                child: Text(
                    'خدمات (برش، رزوه و خم، پانچ، لیزر، دریل یا خدمت دلخواه)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              HelpBadge(topic: 'services', size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ActionChip(
                avatar: const Icon(Icons.content_cut, size: 16),
                label: const Text('+ برش'),
                onPressed: () =>
                    _addService('برش', spec.supportsCutCount ? 'cut' : 'piece'),
              ),
              ActionChip(
                avatar: const Icon(Icons.build_outlined, size: 16),
                label: const Text('+ رزوه و خم'),
                onPressed: () => _addService('رزوه و خم', 'piece'),
              ),
              ActionChip(
                avatar: const Icon(Icons.adjust, size: 16),
                label: const Text('+ پانچ'),
                onPressed: () => _addService('پانچ', 'manual'),
              ),
              ActionChip(
                avatar: const Icon(Icons.bolt_outlined, size: 16),
                label: const Text('+ لیزر'),
                onPressed: () =>
                    _addService('لیزر', spec.hasMetres ? 'm' : 'kg'),
              ),
              ActionChip(
                avatar: const Icon(Icons.precision_manufacturing_outlined, size: 16),
                label: const Text('+ دریل'),
                onPressed: () => _addService('دریل', 'manual'),
              ),
              ActionChip(
                avatar: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('+ خدمت دلخواه'),
                onPressed: () => _addService('سایر خدمات', 'kg'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _services.length; i++)
            _buildServiceCard(i, _services[i], res, serviceUnitOptions),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: _numField('کرایه حمل کل (تومان)', shippingCtl,
                      helpTopic: 'services')),
              const SizedBox(width: 10),
              Expanded(child: _numField('مالیات (٪)', taxPctCtl, helpTopic: 'tax')),
            ],
          ),
          if ((number(taxPctCtl.text) ?? 0) > 0 && _services.isNotEmpty)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('مالیات روی جمع کالا و خدمات اعمال شود'),
              value: taxIncludesServices,
              onChanged: (v) => setState(() => taxIncludesServices = v),
            ),
          if (costError != null)
            infoBox('خطا در بخش قیمت/خدمات', costError, color: Colors.red),
          if (orderCost != null) ...[
            const SizedBox(height: 8),
            _buildOrderCostCard(context, res, orderCost, preset?.label),
          ],
        ],
      ],
    );
  }

  Widget _buildServiceCard(
    int index,
    _ServiceDraft s,
    ProductConversionResult res,
    Map<String, String> serviceUnitOptions,
  ) {
    if (!serviceUnitOptions.containsKey(s.unit)) {
      s.unit = 'kg';
    }
    final isFlat = s.unit == 'flat';
    final isManualOnly = s.unit == 'manual';
    final autoQty = ProductConverter.unitQuantityFromResult(res, s.unit);
    final effQty = isFlat
        ? 1.0
        : (isManualOnly || !s.autoFromProduct)
            ? (number(s.qtyCtl.text) ?? 0)
            : autoQty;
    final unitP = number(s.priceCtl.text) ?? 0;
    final lineTotal = effQty * unitP;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: s.nameCtl,
                    decoration: const InputDecoration(labelText: 'نام خدمت'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'حذف خدمت',
                  onPressed: () => setState(() {
                    _services.removeAt(index).dispose();
                  }),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 10),
            selectField(
              'مبنای محاسبه این خدمت',
              s.unit,
              serviceUnitOptions,
              (v) => setState(() {
                s.unit = v;
                if (v == 'manual' || v == 'flat') {
                  s.autoFromProduct = false;
                }
              }),
            ),
            if (!isFlat && !isManualOnly)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                    'مقدار خودکار از کالا (${fmt(autoQty, decimals: 2)} ${ProductConverter.unitLabel(spec, s.unit)})'),
                value: s.autoFromProduct,
                onChanged: (v) => setState(() {
                  s.autoFromProduct = v;
                  if (!v && number(s.qtyCtl.text) == null) {
                    s.qtyCtl.text = fmt(autoQty, decimals: 2);
                  }
                }),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isFlat && (isManualOnly || !s.autoFromProduct)) ...[
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: s.qtyCtl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'مقدار خدمت'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: s.priceCtl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isFlat ? 'مبلغ کل خدمت (تومان)' : 'نرخ واحد خدمت (تومان)',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (lineTotal > 0) ...[
              const SizedBox(height: 8),
              Text(
                'جمع ${s.nameCtl.text}: ${fmt(lineTotal)} تومان',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: teal, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCostCard(
    BuildContext context,
    ProductConversionResult res,
    OrderCostResult cost,
    String? presetLabel,
  ) {
    final summaryText = StringBuffer()
      ..writeln('خلاصه محاسبه ${spec.title}${presetLabel != null ? ' ($presetLabel)' : ''}')
      ..writeln('وزن کل: ${fmt(res.totalKg, decimals: 2)} کیلوگرم (${fmt(res.totalTon, decimals: 3)} تن)')
      ..writeln(spec.hasMetres ? 'متراژ: ${fmt(res.totalMetres, decimals: 2)} متر' : '')
      ..writeln('تعداد: ${fmt(res.totalPieces, decimals: 2)} ${spec.pieceLabel}')
      ..writeln('قیمت پایه کالا: ${fmt(cost.baseCost)} تومان')
      ..writeln('جمع خدمات: ${fmt(cost.servicesTotal)} تومان')
      ..writeln('مبلغ نهایی: ${fmt(cost.grandTotal)} تومان');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: teal.withOpacity(.08),
        border: Border.all(color: teal.withOpacity(.30)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('قیمت نهایی سفارش و ریز خدمات',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                tooltip: 'کپی خلاصه فاکتور',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: summaryText.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('خلاصه محاسبه کپی شد.')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
          Text(
            '${fmt(cost.grandTotal)} تومان',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: ink),
          ),
          Text(moneyWords(cost.grandTotal),
              style: const TextStyle(fontSize: 11, color: muted)),
          const Divider(height: 18),
          Text('• مبلغ پایه کالا: ${fmt(cost.baseCost)} تومان'),
          if (cost.serviceLines.isNotEmpty) ...[
            Text('• جمع خدمات (${fmt(cost.serviceLines.length)} مورد): ${fmt(cost.servicesTotal)} تومان'),
            for (final line in cost.serviceLines)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 2),
                child: Text(
                  '- ${line.name} (${fmt(line.effectiveQuantity, decimals: 2)} ${ProductConverter.unitLabel(spec, line.unit)} × ${fmt(line.unitPrice)}): ${fmt(line.lineTotal)} تومان',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ),
          ],
          if (cost.shipping > 0)
            Text('• کرایه حمل: ${fmt(cost.shipping)} تومان'),
          if (cost.taxAmount > 0)
            Text('• مالیات (${fmt(cost.taxPercent, decimals: 1)}٪): ${fmt(cost.taxAmount)} تومان'),
          const Divider(height: 18),
          const Text('نرخ تمام‌شده نهایی (با خدمات و حمل) در هر واحد:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (cost.finalPerKg != null)
            Text('• هر کیلوگرم: ${fmt(cost.finalPerKg!)} تومان'),
          Text('• هر تن: ${fmt((cost.finalPerKg ?? 0) * 1000)} تومان'),
          if (cost.finalPerMetre != null)
            Text('• هر متر: ${fmt(cost.finalPerMetre!)} تومان'),
          if (spec.hasArea && res.totalAreaM2 > 0)
            Text('• هر مترمربع: ${fmt(cost.grandTotal / res.totalAreaM2)} تومان'),
          if (cost.finalPerPiece != null)
            Text('• هر ${ProductConverter.unitLabel(spec, 'piece')}: ${fmt(cost.finalPerPiece!)} تومان'),
          if (res.totalCuts > 0)
            Text('• هر عدد (برش‌خورده): ${fmt(cost.grandTotal / res.totalCuts)} تومان'),
          if (res.totalBundles > 0)
            Text('• هر ${spec.bundleLabel}: ${fmt(cost.grandTotal / res.totalBundles)} تومان'),
        ],
      ),
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
