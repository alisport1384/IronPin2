import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/market.dart';
import '../domain/market_tables.dart';
import '../domain/product_converter.dart';
import 'common.dart';
import 'visual_help.dart';

class _CutServiceDraft {
  final int id;
  final TextEditingController nameCtl;
  final TextEditingController qtyCtl;
  final TextEditingController priceCtl;
  String unit;
  bool autoFromProduct;

  _CutServiceDraft({
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

/// Experimental isolated view for cut-to-size (قطعه برش‌خورده) calculations.
/// Stock sheet/branch dimensions are hidden and have ZERO effect unless
/// "تأمین از شیت/شاخه فابریک و محاسبه پرت" is turned ON.
class CutCalculatorView extends StatefulWidget {
  const CutCalculatorView({super.key});

  @override
  State<CutCalculatorView> createState() => _CutCalculatorViewState();
}

class _CutCalculatorViewState extends State<CutCalculatorView> {
  static final List<ConverterProductSpec> _cutProducts =
      converterProducts.where((p) => p.supportsCutCount).toList();

  String productId = 'plate';
  String alloyId = 'steel';
  String inputUnit = 'cut';
  String priceUnit = 'kg';

  bool usePreset = false;
  bool useHeavyPreset = false;
  String? presetId;

  bool cutDimsInCm = false;

  // Toggle for stock sheet/branch allocation & waste (OFF by default).
  bool includeStockWaste = false;
  bool chargeWasteInBasePrice = true;

  final sectionCtls = <String, TextEditingController>{};
  final densityCtl = TextEditingController(text: '۷۸۵۰');
  final cutWidthCtl = TextEditingController(text: '۳۰۰');
  final cutLengthCtl = TextEditingController(text: '۴۰۰');
  final stockWidthCtl = TextEditingController(text: '۱۲۵۰');
  final stockLengthCtl = TextEditingController(text: '۲٫۵');
  final inputValueCtl = TextEditingController(text: '۱۰');
  final unitPriceCtl = TextEditingController();
  final shippingCtl = TextEditingController(text: '۰');
  final taxPctCtl = TextEditingController(text: '۰');
  bool taxIncludesServices = true;

  int _nextServiceId = 1;
  final List<_CutServiceDraft> _services = [];

  ConverterProductSpec get spec =>
      _cutProducts.firstWhere((p) => p.id == productId);

  MetalAlloy get alloy => metalAlloys.firstWhere((a) => a.id == alloyId);

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

  /// Section fields excluding stock length, bundle count, and (for plate) stock sheet width.
  List<ConverterField> get _cutSectionFields => spec.fields.where((f) {
        if (f.key == 'pieceLengthM' || f.key == 'piecesPerBundle') return false;
        if (productId == 'plate' && f.key == 'widthMm') return false;
        return true;
      }).toList();

  @override
  void initState() {
    super.initState();
    _initForProduct();
  }

  void _initForProduct() {
    for (final c in sectionCtls.values) {
      c.dispose();
    }
    sectionCtls.clear();
    cutDimsInCm = false;
    for (final f in _cutSectionFields) {
      sectionCtls[f.key] = TextEditingController(
          text: fmt(f.initial, decimals: f.integerOnly ? 0 : 2));
    }
    final g = presetGroup;
    useHeavyPreset = false;
    usePreset = g != null && const {'beam', 'hbeam'}.contains(productId);
    presetId =
        g != null && g.lightItems.isNotEmpty ? g.lightItems.first.id : null;
    if (usePreset && selectedPreset != null) {
      _applyPresetValues(selectedPreset!);
    }

    cutWidthCtl.text = '۳۰۰';
    cutLengthCtl.text = productId == 'plate' ? '۴۰۰' : '۱۵۰۰';
    stockWidthCtl.text = '۱۲۵۰';
    final defLen = spec.fields
        .where((f) => f.key == 'pieceLengthM')
        .map((f) => f.initial)
        .firstOrNull;
    stockLengthCtl.text = fmt(defLen ?? 6, decimals: 2);
    inputUnit = 'cut';
    if (!const {'kg', 'ton', 'cut', 'm', 'm2'}.contains(priceUnit)) {
      priceUnit = 'kg';
    }
    if (priceUnit == 'm2' && !spec.hasArea) {
      priceUnit = 'kg';
    }
  }

  void _applyPresetValues(MarketPresetItem item) {
    if (item.defaultPieceLengthM != null) {
      stockLengthCtl.text = fmt(item.defaultPieceLengthM!, decimals: 2);
    }
    if (item.kgPerMetre != null && sectionCtls.containsKey('kgPerMetre')) {
      sectionCtls['kgPerMetre']!.text = fmt(item.kgPerMetre!, decimals: 3);
    }
  }

  void _toggleCmMode(bool toCm) {
    if (toCm == cutDimsInCm) return;
    final factor = toCm ? 0.1 : 10.0;
    for (final ctl in [
      if (productId == 'plate') cutWidthCtl,
      cutLengthCtl,
    ]) {
      final v = number(ctl.text);
      if (v != null) {
        ctl.text = fmt(v * factor, decimals: 3);
      }
    }
    cutDimsInCm = toCm;
  }

  void _addService(String name, String defaultUnit) {
    setState(() {
      _services.add(_CutServiceDraft(
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
      ...sectionCtls.values,
      densityCtl,
      cutWidthCtl,
      cutLengthCtl,
      stockWidthCtl,
      stockLengthCtl,
      inputValueCtl,
      unitPriceCtl,
      shippingCtl,
      taxPctCtl,
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
      final preset = selectedPreset;
      final usePresetKgm = preset?.kgPerMetre != null && preset!.kgPerMetre! > 0;
      if (!usePresetKgm) {
        for (final f in _cutSectionFields) {
          final raw = number(sectionCtls[f.key]!.text);
          if (raw == null) {
            return (result: null, error: '${f.label}: عدد معتبر وارد کنید.');
          }
          fields[f.key] = raw;
        }
      } else {
        // Plate doesn't use preset kg/m; still keep any plate thickness/coat if present
        for (final f in _cutSectionFields) {
          final raw = number(sectionCtls[f.key]?.text ?? '');
          if (raw != null) fields[f.key] = raw;
        }
      }

      final q = number(inputValueCtl.text);
      if (q == null) {
        return (result: null, error: 'مقدار سفارش را وارد کنید.');
      }

      final cutLenRaw = number(cutLengthCtl.text);
      if (cutLenRaw == null) {
        return (result: null, error: 'طول قطعه برش‌خورده را وارد کنید.');
      }
      final cutLenMm = cutDimsInCm ? cutLenRaw * 10.0 : cutLenRaw;

      double? cutWidMm;
      if (productId == 'plate') {
        final cutWidRaw = number(cutWidthCtl.text);
        if (cutWidRaw == null) {
          return (result: null, error: 'عرض قطعه برش‌خورده را وارد کنید.');
        }
        cutWidMm = cutDimsInCm ? cutWidRaw * 10.0 : cutWidRaw;
      }

      double? stockW;
      double? stockL;
      if (includeStockWaste) {
        stockL = number(stockLengthCtl.text);
        if (stockL == null) {
          return (result: null, error: 'طول شیت/شاخه فابریک را وارد کنید.');
        }
        if (productId == 'plate') {
          stockW = number(stockWidthCtl.text);
          if (stockW == null) {
            return (result: null, error: 'عرض ورق فابریک را وارد کنید.');
          }
        }
      }

      final res = ProductConverter.convertCutPiece(
        productId: productId,
        fields: fields,
        density: d,
        inputUnit: inputUnit,
        inputValue: q,
        cutLengthMm: cutLenMm,
        cutWidthMm: cutWidMm,
        overrideKgPerMetre: preset?.kgPerMetre,
        includeStockWaste: includeStockWaste,
        stockWidthMm: stockW,
        stockLengthM: stockL,
      );
      return (result: res, error: null);
    } on FormatException catch (e) {
      return (result: null, error: e.message);
    } catch (_) {
      return (result: null, error: 'مقادیر ورودی معتبر نیستند.');
    }
  }

  Widget _numField(String label, TextEditingController ctl,
          {String? helpTopic}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon:
                helpTopic == null ? null : HelpBadge(topic: helpTopic, size: 16),
          ),
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final eval = _evaluate();
    final res = eval.result;
    final group = presetGroup;
    final preset = selectedPreset;

    final cutUnitOptions = <String, String>{
      'cut': 'عدد (قطعه برش‌خورده)',
      'kg': 'کیلوگرم',
      'ton': 'تن',
      if (spec.hasArea) 'm2': 'مترمربع',
      'm': 'متر طول برش‌خورده',
    };

    final cutPriceOptions = <String, String>{
      'kg': 'هر کیلوگرم',
      'ton': 'هر تن',
      'cut': 'هر عدد (قطعه برش‌خورده)',
      if (spec.hasArea) 'm2': 'هر مترمربع',
      'm': 'هر متر طول',
      if (includeStockWaste && res?.cutAllocation?.fitsInStock == true)
        'piece': 'هر ${spec.pieceLabel} فابریک',
    };

    final serviceUnitOptions = <String, String>{
      'cut': 'هر عدد (برش‌خورده)',
      'kg': 'هر کیلوگرم',
      'ton': 'هر تن',
      'm': 'هر متر',
      if (spec.hasArea) 'm2': 'هر مترمربع',
      if (includeStockWaste && res?.cutAllocation?.fitsInStock == true)
        'piece': 'هر ${spec.pieceLabel} فابریک',
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
              includeWasteInBaseCost:
                  includeStockWaste && chargeWasteInBasePrice,
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
        infoBox(
          'حالت برش‌خورده مستقل (آزمایشی)',
          'در این تب، ابعاد ورق/شاخه فابریک قبل از برش هیچ تاثیری روی وزن ندارند و فقط ضخامت، قطر یا ابعاد مقطع همراه با اندازه برش‌خورده محاسبه می‌شوند. اگر می‌خواهید مصرف ورق فابریک و پرت هم حساب شود، کلید «تأمین از شیت/شاخه فابریک» را روشن کنید.',
          color: teal,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: Text('۱. انتخاب کالا و مشخصات مقطع برش‌خورده',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            HelpBadge(topic: productId, size: 17),
          ],
        ),
        const SizedBox(height: 10),
        selectField(
          'کالای آهن‌آلات',
          productId,
          {for (final p in _cutProducts) p.id: p.title},
          (v) => setState(() {
            productId = v;
            _initForProduct();
          }),
          helpTopic: productId,
        ),
        if (group != null) ...[
          const SizedBox(height: 10),
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
                      label: Text('ابعاد / قطر / ضخامت دستی'),
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
        if (!usePreset && spec.usesDensity) ...[
          const SizedBox(height: 10),
          selectField(
            'جنس / آلیاژ',
            alloyId,
            {
              for (final a in metalAlloys)
                a.id: '${a.label} (${fmt(a.density)} kg/m³)'
            },
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
        const SizedBox(height: 6),
        if (!usePreset)
          for (final f in _cutSectionFields)
            _numField(f.label, sectionCtls[f.key]!, helpTopic: productId),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('ورود عرض و طول قطعه برش‌خورده به سانتی‌متر'),
          subtitle: const Text('مثلاً پلیت ۲۰×۲۰ سانتی‌متر یا قطعه ۱۵۰ سانتی‌متری'),
          value: cutDimsInCm,
          onChanged: (v) => setState(() => _toggleCmMode(v)),
        ),
        if (productId == 'plate')
          _numField(
            cutDimsInCm
                ? 'عرض هر قطعه برش‌خورده (سانتی‌متر)'
                : 'عرض هر قطعه برش‌خورده (میلی‌متر)',
            cutWidthCtl,
            helpTopic: 'cut_piece',
          ),
        _numField(
          cutDimsInCm
              ? 'طول هر قطعه برش‌خورده (سانتی‌متر)'
              : 'طول هر قطعه برش‌خورده (میلی‌متر)',
          cutLengthCtl,
          helpTopic: 'cut_piece',
        ),
        const Divider(height: 24),
        const Row(
          children: [
            Expanded(
              child: Text('۲. مقدار سفارش برش‌خورده چقدر است؟',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            HelpBadge(topic: 'order_qty', size: 17),
          ],
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
                cutUnitOptions,
                (v) => setState(() => inputUnit = v),
                helpTopic: 'order_qty',
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Row(
            children: [
              Expanded(child: Text('تأمین از شیت/شاخه فابریک و محاسبه پرت')),
              HelpBadge(topic: 'cut_piece', size: 16),
            ],
          ),
          subtitle: const Text(
              'پیش‌فرض خاموش؛ روشن کنید تا تعداد شیت/شاخه فابریک و پرت هم حساب شود'),
          value: includeStockWaste,
          onChanged: (v) => setState(() {
            includeStockWaste = v;
            if (!v && priceUnit == 'piece') {
              priceUnit = 'kg';
            }
          }),
        ),
        if (includeStockWaste) ...[
          if (productId == 'plate') ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('ورق ۱×۲ متر'),
                  onPressed: () => setState(() {
                    stockWidthCtl.text = '۱۰۰۰';
                    stockLengthCtl.text = '۲';
                  }),
                ),
                ActionChip(
                  label: const Text('ورق ۱٫۲۵×۲٫۵ متر'),
                  onPressed: () => setState(() {
                    stockWidthCtl.text = '۱۲۵۰';
                    stockLengthCtl.text = '۲٫۵';
                  }),
                ),
                ActionChip(
                  label: const Text('ورق ۱٫۵×۶ متر'),
                  onPressed: () => setState(() {
                    stockWidthCtl.text = '۱۵۰۰';
                    stockLengthCtl.text = '۶';
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _numField('عرض ورق فابریک (میلی‌متر)', stockWidthCtl,
                helpTopic: 'plate'),
          ],
          _numField(
            productId == 'plate'
                ? 'طول ورق فابریک (متر)'
                : 'طول شاخه فابریک (متر؛ مثلاً ۶ یا ۱۲)',
            stockLengthCtl,
            helpTopic: productId,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('اضافه شدن وزن پرت به قیمت نهایی کالا'),
            subtitle: const Text(
                'وقتی ورق برش‌خورده خریداری می‌شود و پرت هم روی فاکتور شما حساب می‌شود'),
            value: chargeWasteInBasePrice,
            onChanged: (v) => setState(() => chargeWasteInBasePrice = v),
          ),
        ],
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
                      ? 'نتیجه قطعه برش‌خورده: ${spec.title} (${preset.label})'
                      : 'نتیجه قطعه برش‌خورده: ${spec.title}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                _CutResultLine(
                  label: 'وزن یک قطعه برش‌خورده',
                  value: '${fmt(res.kgPerCut, decimals: 3)} کیلوگرم',
                  highlight: true,
                ),
                _CutResultLine(
                  label: 'وزن خالص کل قطعات',
                  value:
                      '${fmt(res.totalKg, decimals: 3)} کیلو (${fmt(res.totalTon, decimals: 4)} تن)',
                  highlight: true,
                ),
                _CutResultLine(
                  label: 'تعداد قطعات برش‌خورده',
                  value: '${fmt(res.totalCuts, decimals: 2)} عدد',
                ),
                if (spec.hasArea && res.totalAreaM2 > 0)
                  _CutResultLine(
                    label: 'مساحت خالص کل قطعات',
                    value: '${fmt(res.totalAreaM2, decimals: 3)} مترمربع',
                  ),
                _CutResultLine(
                  label: 'جمع طول برش‌خورده',
                  value: '${fmt(res.totalMetres, decimals: 3)} متر',
                ),
                if (res.cutAllocation != null) ...[
                  const Divider(color: Colors.white24, height: 20),
                  if (res.cutAllocation!.fitsInStock) ...[
                    _CutResultLine(
                      label:
                          'نیاز از ${res.cutAllocation!.isSheet ? 'شیت' : 'شاخه'} فابریک',
                      value:
                          '${fmt(res.cutAllocation!.requiredStockPieces)} ${spec.pieceLabel} (${fmt(res.cutAllocation!.cutsPerStockPiece)} عدد در هر ${res.cutAllocation!.isSheet ? 'شیت' : 'شاخه'})',
                    ),
                    _CutResultLine(
                      label: 'وزن کل فابریک مصرفی',
                      value:
                          '${fmt(res.cutAllocation!.stockTotalKg, decimals: 2)} کیلوگرم',
                    ),
                    _CutResultLine(
                      label: 'پرت برش',
                      value:
                          '${fmt(res.cutAllocation!.wasteKg, decimals: 2)} کیلوگرم (${fmt(res.cutAllocation!.wastePercent, decimals: 1)}٪)',
                    ),
                  ] else
                    const Text(
                      'ابعاد قطعه برش‌خورده از شیت/شاخه فابریک بزرگ‌تر است.',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 28),
          const Row(
            children: [
              Expanded(
                child: Text('۳. قیمت پایه، خدمات برش و قیمت نهایی',
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
                  cutPriceOptions,
                  (v) => setState(() => priceUnit = v),
                  helpTopic: 'basis',
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ActionChip(
                avatar: const Icon(Icons.content_cut, size: 16),
                label: const Text('+ برش'),
                onPressed: () => _addService('برش', 'cut'),
              ),
              ActionChip(
                avatar: const Icon(Icons.build_outlined, size: 16),
                label: const Text('+ رزوه و خم'),
                onPressed: () => _addService('رزوه و خم', 'cut'),
              ),
              ActionChip(
                avatar: const Icon(Icons.adjust, size: 16),
                label: const Text('+ پانچ'),
                onPressed: () => _addService('پانچ', 'manual'),
              ),
              ActionChip(
                avatar: const Icon(Icons.bolt_outlined, size: 16),
                label: const Text('+ لیزر'),
                onPressed: () => _addService('لیزر', 'm'),
              ),
              ActionChip(
                avatar:
                    const Icon(Icons.precision_manufacturing_outlined, size: 16),
                label: const Text('+ دریل'),
                onPressed: () => _addService('دریل', 'manual'),
              ),
              ActionChip(
                avatar: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('+ خدمت دلخواه'),
                onPressed: () => _addService('خدمت کارگاهی', 'flat'),
              ),
            ],
          ),
          if (_services.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final s in _services)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: s.nameCtl,
                              decoration:
                                  const InputDecoration(labelText: 'نام خدمت'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          IconButton(
                            tooltip: 'حذف خدمت',
                            onPressed: () => setState(() {
                              _services.remove(s);
                              s.dispose();
                            }),
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: selectField(
                              'واحد محاسبه',
                              s.unit,
                              serviceUnitOptions,
                              (v) => setState(() {
                                s.unit = v;
                                if (v == 'manual' || v == 'flat') {
                                  s.autoFromProduct = false;
                                }
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (s.unit != 'flat')
                            Expanded(
                              flex: 3,
                              child: s.unit != 'manual' && s.autoFromProduct
                                  ? InputDecorator(
                                      decoration: const InputDecoration(
                                          labelText: 'تعداد خودکار'),
                                      child: Text(
                                        fmt(
                                          ProductConverter.unitQuantityFromResult(
                                              res, s.unit),
                                          decimals: 2,
                                        ),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : TextField(
                                      controller: s.qtyCtl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                          labelText: 'تعداد'),
                                      onChanged: (_) => setState(() {}),
                                    ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: s.priceCtl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: s.unit == 'flat'
                                    ? 'مبلغ کل (تومان)'
                                    : 'نرخ واحد (تومان)',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      if (s.unit != 'manual' && s.unit != 'flat')
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                              'خواندن خودکار مقدار از سفارش بالا',
                              style: TextStyle(fontSize: 12)),
                          value: s.autoFromProduct,
                          onChanged: (v) =>
                              setState(() => s.autoFromProduct = v),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _numField('کرایه حمل کل (تومان)', shippingCtl,
                      helpTopic: 'services')),
              const SizedBox(width: 10),
              Expanded(
                  child: _numField('مالیات (٪)', taxPctCtl, helpTopic: 'tax')),
            ],
          ),
          if (costError != null)
            infoBox('خطا در بخش قیمت/خدمات', costError, color: Colors.red),
          if (orderCost != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: teal.withOpacity(0.1),
                border: Border.all(color: teal.withOpacity(0.45)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('جمع نهایی سفارش برش‌خورده',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      IconButton(
                        tooltip: 'کپی خلاصه فاکتور',
                        onPressed: () {
                          final buf = StringBuffer()
                            ..writeln('کالا (برش‌خورده): ${spec.title}')
                            ..writeln(
                                'تعداد: ${fmt(res.totalCuts, decimals: 2)} عدد | وزن هر عدد: ${fmt(res.kgPerCut, decimals: 3)} کیلو')
                            ..writeln(
                                'وزن خالص کل: ${fmt(res.totalKg, decimals: 2)} کیلو')
                            ..writeln(
                                'جمع نهایی: ${fmt(orderCost!.grandTotal)} تومان');
                          Clipboard.setData(
                              ClipboardData(text: buf.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('خلاصه فاکتور کپی شد.')));
                        },
                        icon: const Icon(Icons.copy_outlined, size: 19),
                      ),
                    ],
                  ),
                  if (includeStockWaste &&
                      chargeWasteInBasePrice &&
                      res.cutAllocation != null &&
                      res.cutAllocation!.fitsInStock)
                    Text(
                      'محاسبه قیمت پایه روی ${fmt(orderCost.baseQuantity, decimals: 2)} ${ProductConverter.unitLabel(spec, priceUnit)} (با احتساب پرت فابریک)',
                      style: const TextStyle(fontSize: 11, color: teal),
                    ),
                  if (orderCost.baseCost > 0)
                    Text(
                      'بهای کالا: ${fmt(orderCost.baseCost)} تومان',
                      style: const TextStyle(fontSize: 13),
                    ),
                  for (final ln in orderCost.serviceLines)
                    Text(
                      '${ln.name}: ${fmt(ln.effectiveQuantity, decimals: 2)} × ${fmt(ln.unitPrice)} = ${fmt(ln.lineTotal)} تومان',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  if (orderCost.shipping > 0)
                    Text('حمل: ${fmt(orderCost.shipping)} تومان',
                        style: const TextStyle(fontSize: 12, color: muted)),
                  if (orderCost.taxAmount > 0)
                    Text(
                        'مالیات (${fmt(orderCost.taxPercent)}٪): ${fmt(orderCost.taxAmount)} تومان',
                        style: const TextStyle(fontSize: 12, color: muted)),
                  const Divider(height: 16),
                  Text(
                    'مبلغ نهایی: ${fmt(orderCost.grandTotal)} تومان',
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: teal),
                  ),
                  if (orderCost.finalPerKg != null)
                    Text(
                      'تمام‌شده هر کیلو خالص: ${fmt(orderCost.finalPerKg!)} تومان | هر عدد: ${fmt(orderCost.grandTotal / res.totalCuts)} تومان',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _CutResultLine extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _CutResultLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            Text(
              value,
              style: TextStyle(
                color: highlight ? const Color(0xff62e0ce) : Colors.white,
                fontSize: highlight ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}
