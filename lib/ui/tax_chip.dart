import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../domain/market.dart';
import '../domain/money.dart';
import '../domain/tax_policy.dart';
import 'common.dart';
import 'visual_help.dart';

/// کنترل مالیات در تب قیمت و تب رنج: پیش‌فرض خاموش، درصد پیش‌فرض ۱۳.
/// با روشن شدن، به همه قیمت‌های نمایش‌داده‌شدهٔ هر دو تب اضافه می‌شود.
class TaxChip extends StatelessWidget {
  final MarketController c;
  const TaxChip({super.key, required this.c});

  static double _parsePercent(String raw) {
    final t = latin(raw).trim().replaceAll('،', '.').replaceAll(',', '.');
    final v = double.tryParse(t);
    if (v == null || v < 0 || v > 100) return TaxPolicy.percent;
    return v;
  }

  static String _pctLabel(double p) =>
      p == p.roundToDouble() ? '${p.round()}' : '$p';

  Future<void> _edit(BuildContext context) async {
    var enabled = TaxPolicy.enabled;
    var percent = TaxPolicy.percent;
    final field = TextEditingController(text: _pctLabel(percent));
    final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialog) => AlertDialog(
                  title: const Text('مالیات بر ارزش افزوده'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'افزودن مالیات بر همه قیمت‌های نمایش‌داده‌شده'),
                        subtitle: const Text(
                            'فقط نمایش؛ مبلغ ثبت‌شده منبع دست نمی‌خورد'),
                        value: enabled,
                        onChanged: (v) => setDialog(() => enabled = v)),
                    TextField(
                        controller: field,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'درصد مالیات (پیش‌فرض ۱۳)',
                            suffixText: '٪'))
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('لغو')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('ثبت'))
                  ],
                )));
    final raw = field.text;
    field.dispose();
    if (saved != true) return;
    await c.setTax(enabled: enabled, percent: _parsePercent(raw));
  }

  @override
  Widget build(BuildContext context) {
    final on = TaxPolicy.enabled;
    final label =
        'مالیات: ${on ? '${faDigits(_pctLabel(TaxPolicy.percent))}٪' : 'خاموش'}';
    return Align(
        alignment: Alignment.centerRight,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          TextButton(
              onPressed: () => _edit(context),
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  visualDensity: VisualDensity.compact),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(on ? Icons.percent : Icons.percent_outlined,
                    size: 15, color: teal),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 11, color: ink)),
              ])),
          const HelpBadge(topic: 'tax', size: 15),
        ]));
  }
}
