import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironpin/domain/calculator.dart';
import 'package:ironpin/domain/product_converter.dart';
import 'package:ironpin/ui/calculator_page.dart';

void main() {
  group('ProductConverter domain math', () {
    test('sheet: 10m x 1250mm x 2mm steel converts to kg, m2, sheets, bundles', () {
      final res = ProductConverter.convert(
        productId: 'plate',
        fields: {
          'thicknessMm': 2,
          'widthMm': 1250,
          'pieceLengthM': 2.5,
          'coatGsm': 0,
          'piecesPerBundle': 20,
        },
        density: 7850,
        inputUnit: 'm',
        inputValue: 10,
      );
      expect(res.totalMetres, closeTo(10, 1e-9));
      expect(res.totalAreaM2, closeTo(12.5, 1e-9));
      expect(res.totalKg, closeTo(196.25, 1e-9));
      expect(res.totalTon, closeTo(0.19625, 1e-9));
      expect(res.totalPieces, closeTo(4, 1e-9));
      expect(res.totalBundles, closeTo(0.2, 1e-9));
    });

    test('alloy density changes output weight accurately (steel vs aluminum vs copper)', () {
      double kgFor(double density) => ProductConverter.convert(
            productId: 'flat',
            fields: {
              'widthMm': 50,
              'thicknessMm': 5,
              'pieceLengthM': 6,
              'piecesPerBundle': 20,
            },
            density: density,
            inputUnit: 'm',
            inputValue: 12,
          ).totalKg;

      expect(kgFor(7850), closeTo(23.55, 1e-9));
      expect(kgFor(2700), closeTo(8.10, 1e-9));
      expect(kgFor(8960), closeTo(26.88, 1e-9));
    });

    test('rebar bundle conversion breaks into whole bundles + remaining branches', () {
      final res = ProductConverter.convert(
        productId: 'rebar',
        fields: {
          'diameterMm': 16,
          'pieceLengthM': 12,
          'piecesPerBundle': 100,
        },
        density: 7850,
        inputUnit: 'piece',
        inputValue: 250,
      );
      expect(res.totalMetres, closeTo(3000, 1e-9));
      expect(res.totalBundles, closeTo(2.5, 1e-9));
      expect(res.bundleBreakdown.wholeBundles, 2);
      expect(res.bundleBreakdown.remainingPieces, closeTo(50, 1e-9));
    });

    test('round-trip bundle -> kg -> m -> piece for RHS & pipe', () {
      final rhs = ProductConverter.convert(
        productId: 'rhs',
        fields: {
          'heightMm': 40,
          'widthMm': 40,
          'thicknessMm': 2,
          'pieceLengthM': 6,
          'piecesPerBundle': 12,
        },
        density: 7850,
        inputUnit: 'bundle',
        inputValue: 2,
      );
      expect(rhs.totalPieces, closeTo(24, 1e-9));
      expect(rhs.totalMetres, closeTo(144, 1e-9));

      final back = ProductConverter.convert(
        productId: 'rhs',
        fields: {
          'heightMm': 40,
          'widthMm': 40,
          'thicknessMm': 2,
          'pieceLengthM': 6,
          'piecesPerBundle': 12,
        },
        density: 7850,
        inputUnit: 'kg',
        inputValue: rhs.totalKg,
      );
      expect(back.totalBundles, closeTo(2, 1e-9));

      final pipe = ProductConverter.convert(
        productId: 'pipe',
        fields: {
          'odMm': 48.3,
          'thicknessMm': 2,
          'pieceLengthM': 6,
          'piecesPerBundle': 10,
        },
        density: 7900,
        inputUnit: 'm',
        inputValue: 6,
      );
      expect(
        pipe.totalKg,
        closeTo(math.pi * 2 * 46.3 * 7900 / 1e6 * 6, 1e-8),
      );
    });

    test('wire coils & catalog beams & mesh & rabitz work cleanly', () {
      final wire = ProductConverter.convert(
        productId: 'wire',
        fields: {
          'diameterMm': 2,
          'pieceLengthM': 100,
          'piecesPerBundle': 10,
        },
        density: 7850,
        inputUnit: 'piece',
        inputValue: 3,
      );
      expect(wire.totalMetres, closeTo(300, 1e-9));

      final beam = ProductConverter.convert(
        productId: 'catalog_kgm',
        fields: {
          'kgPerMetre': 18.8,
          'pieceLengthM': 12,
          'piecesPerBundle': 6,
        },
        density: 7850,
        inputUnit: 'ton',
        inputValue: 1.128,
      );
      expect(beam.totalMetres, closeTo(60, 1e-6));
      expect(beam.totalPieces, closeTo(5, 1e-6));

      final pack = ProductConverter.convert(
        productId: 'piece_pack',
        fields: {
          'kgPerPiece': 0.9,
          'areaPerPieceM2': 1.44,
          'piecesPerBundle': 10,
        },
        density: 7850,
        inputUnit: 'bundle',
        inputValue: 2,
      );
      expect(pack.totalPieces, closeTo(20, 1e-9));
      expect(pack.totalKg, closeTo(18, 1e-9));
      expect(pack.totalAreaM2, closeTo(28.8, 1e-9));
    });

    test('cut_plate & unit_item support direct count (عدد) conversion', () {
      final plate = ProductConverter.convert(
        productId: 'cut_plate',
        fields: {
          'thicknessMm': 10,
          'widthMm': 300,
          'lengthMm': 300,
          'piecesPerBundle': 10,
        },
        density: 7850,
        inputUnit: 'piece',
        inputValue: 100,
      );
      expect(plate.kgPerPiece, closeTo(7.065, 1e-9));
      expect(plate.totalKg, closeTo(706.5, 1e-9));
      expect(plate.totalAreaM2, closeTo(9.0, 1e-9));
      expect(plate.totalBundles, closeTo(10.0, 1e-9));

      final item = ProductConverter.convert(
        productId: 'unit_item',
        fields: {
          'kgPerPiece': 2.5,
          'piecesPerBundle': 10,
        },
        density: 7850,
        inputUnit: 'ton',
        inputValue: 1,
      );
      expect(item.totalPieces, closeTo(400, 1e-9));
      expect(item.totalBundles, closeTo(40, 1e-9));
      expect(
        ProductConverter.unitLabel(
            converterProducts.firstWhere((p) => p.id == 'unit_item'), 'piece'),
        'عدد',
      );
      expect(
        ProductConverter.unitLabel(
            converterProducts.firstWhere((p) => p.id == 'rebar'), 'piece'),
        'شاخه',
      );
      expect(
        ProductConverter.unitLabel(
            converterProducts.firstWhere((p) => p.id == 'plate'), 'piece'),
        'برگ (شیت)',
      );
      expect(
        ProductConverter.unitLabel(
            converterProducts.firstWhere((p) => p.id == 'rebar'), 'cut'),
        'عدد (قطعه برش‌خورده)',
      );
    });

    test('cut (عدد) is distinct from sheet/branch and calculates stock pieces & waste', () {
      // 50 cut plates of 300x400x10mm from standard 1250x2500mm sheets
      final cutPlate = ProductConverter.convert(
        productId: 'plate',
        fields: {
          'thicknessMm': 10,
          'widthMm': 1250,
          'pieceLengthM': 2.5,
          'coatGsm': 0,
          'piecesPerBundle': 20,
        },
        density: 7850,
        inputUnit: 'cut',
        inputValue: 50,
        cutWidthMm: 300,
        cutLengthMm: 400,
      );
      expect(cutPlate.totalCuts, closeTo(50, 1e-9));
      expect(cutPlate.kgPerCut, closeTo(9.42, 1e-9));
      expect(cutPlate.totalKg, closeTo(471.0, 1e-9));
      expect(cutPlate.totalAreaM2, closeTo(6.0, 1e-9));
      expect(cutPlate.cutAllocation, isNotNull);
      expect(cutPlate.cutAllocation!.fitsInStock, isTrue);
      expect(cutPlate.cutAllocation!.cutsPerStockPiece, 24);
      expect(cutPlate.cutAllocation!.requiredStockPieces, 3);
      expect(cutPlate.cutAllocation!.wasteKg, greaterThan(0));

      // 15 cut rebar pieces of 1500mm (1.5m) from standard 12m branches
      final cutRebar = ProductConverter.convert(
        productId: 'rebar',
        fields: {
          'diameterMm': 16,
          'pieceLengthM': 12,
          'piecesPerBundle': 100,
        },
        density: 7850,
        inputUnit: 'cut',
        inputValue: 15,
        cutLengthMm: 1500,
      );
      expect(cutRebar.totalMetres, closeTo(22.5, 1e-9));
      expect(cutRebar.cutAllocation!.cutsPerStockPiece, 8);
      expect(cutRebar.cutAllocation!.requiredStockPieces, 2);
      expect(cutRebar.cutAllocation!.wasteLengthM, closeTo(1.5, 1e-9));
    });

    test('SteelCalculator supports cut (عدد) with stock allocation and distinct cost pricing', () {
      final res = SteelCalculator.calculate(
        shape: 'plate',
        values: {'b': 1250, 't': 10, 'coat': 0},
        density: 7850,
        inputUnit: 'cut',
        quantity: 50,
        lengthPerPiece: 2.5,
        cutWidthMm: 300,
        cutLengthMm: 400,
      );
      expect(res.pieces, closeTo(50, 1e-9));
      expect(res.kg, closeTo(471.0, 1e-9));
      expect(res.cutAllocation, isNotNull);
      expect(res.cutAllocation!.requiredStockPieces, 3);
      expect(res.cutAllocation!.cutsPerStockPiece, 24);
      // Price per cut piece vs price per full sheet
      expect(SteelCalculator.cost(res, 'cut', 100000), closeTo(5000000, 1e-6));
      expect(SteelCalculator.cost(res, 'piece', 1000000), closeTo(3000000, 1e-6));
    });

    test('rejects invalid geometry and unsupported units', () {
      expect(
        () => ProductConverter.convert(
          productId: 'pipe',
          fields: {
            'odMm': 20,
            'thicknessMm': 10,
            'pieceLengthM': 6,
            'piecesPerBundle': 10,
          },
          density: 7850,
          inputUnit: 'm',
          inputValue: 6,
        ),
        throwsFormatException,
      );
      expect(
        () => ProductConverter.convert(
          productId: 'rebar',
          fields: {
            'diameterMm': 16,
            'pieceLengthM': 12,
            'piecesPerBundle': 100,
          },
          density: 7850,
          inputUnit: 'm2',
          inputValue: 5,
        ),
        throwsFormatException,
      );
    });
  });

  testWidgets('CalculatorPage switches to ProductConverterView and converts live',
      (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: CalculatorPage())));
    await t.pumpAndSettle();

    expect(find.text('تبدیل واحد کالا'), findsOneWidget);
    await t.tap(find.text('تبدیل واحد کالا'));
    await t.pumpAndSettle();

    expect(find.text('۱. انتخاب کالا و مشخصات اختصاصی'), findsOneWidget);
    // Default sheet: 10m x 1250mm x 2mm steel = 196.250 kg
    expect(find.textContaining('۱۹۶٫۲۵۰ کیلوگرم'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('CalculatorPage simple mode calculates X cut pieces (عدد) and stock allocation',
      (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: CalculatorPage())));
    await t.pumpAndSettle();

    expect(find.text('عدد (برش‌خورده)'), findsOneWidget);
    await t.tap(find.text('عدد (برش‌خورده)'));
    await t.pumpAndSettle();

    expect(find.text('طول هر عدد برش‌خورده (میلی‌متر)'), findsOneWidget);
    expect(find.text('تعداد قطعات برش‌خورده (چند عدد؟)'), findsOneWidget);

    await t.enterText(
        find.widgetWithText(TextField, 'تعداد قطعات برش‌خورده (چند عدد؟)'), '۱۰');
    await t.ensureVisible(find.text('محاسبه'));
    await t.tap(find.text('محاسبه'));
    await t.pumpAndSettle();

    expect(find.textContaining('تعداد برش‌خورده: ۱۰ عدد'), findsOneWidget);
    expect(find.textContaining('تأمین از شاخه فابریک:'), findsOneWidget);
    expect(find.textContaining('پرت / باقیمانده برش:'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
