import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironpin/domain/calculator.dart';
import 'package:ironpin/domain/market_tables.dart';
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

  testWidgets('CalculatorPage opens directly on ProductConverterView and converts live',
      (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: CalculatorPage())));
    await t.pumpAndSettle();

    expect(find.text('ماشین حساب و تبدیل واحد'), findsOneWidget);
    expect(find.text('تبدیل واحد و خدمات'), findsOneWidget);
    expect(find.text('۱. انتخاب کالا، جدول استاندارد یا ابعاد'), findsOneWidget);
    // Default sheet: 10m x 1250mm x 2mm steel = 196.250 kg
    expect(find.textContaining('۱۹۶٫۲۵۰ کیلوگرم'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('CalculatorPage simple mode calculates X cut pieces (عدد) and stock allocation',
      (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: CalculatorPage())));
    await t.pumpAndSettle();
    await t.tap(find.text('فرمولی کلاسیک'));
    await t.pumpAndSettle();

    expect(find.text('عدد (برش‌خورده)'), findsOneWidget);
    await t.ensureVisible(find.text('عدد (برش‌خورده)'));
    await t.pumpAndSettle();
    await t.tap(find.text('عدد (برش‌خورده)'));
    await t.pumpAndSettle();

    expect(find.text('طول هر عدد برش‌خورده (میلی‌متر)'), findsOneWidget);
    expect(find.text('تعداد قطعات برش‌خورده (چند عدد؟)'), findsOneWidget);

    await t.ensureVisible(
        find.widgetWithText(TextField, 'تعداد قطعات برش‌خورده (چند عدد؟)'));
    await t.enterText(
        find.widgetWithText(TextField, 'تعداد قطعات برش‌خورده (چند عدد؟)'), '۱۰');
    await t.ensureVisible(find.text('محاسبه'));
    await t.tap(find.text('محاسبه'));
    await t.pumpAndSettle();

    await t.ensureVisible(find.textContaining('تعداد برش‌خورده: ۱۰ عدد'));
    expect(find.textContaining('تعداد برش‌خورده: ۱۰ عدد'), findsOneWidget);
    expect(find.textContaining('تأمین از شاخه فابریک:'), findsOneWidget);
    expect(find.textContaining('پرت / باقیمانده برش:'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  group('Iranian market presets, light/heavy, new products & services', () {
    test('light vs heavy RHS, H-beam, channel, pipe & angle 8x8 market tables work accurately', () {
      // نبشی ۸ در ۸ (۶ متر = ۵۸ کیلوگرم)
      final angleGroup = marketPresetGroups['angle']!;
      final angle8 = angleGroup.lightItems.firstWhere((e) => e.id == '8');
      final angleRes = ProductConverter.convert(
        productId: 'angle',
        fields: {'leg1Mm': 80, 'leg2Mm': 80, 'thicknessMm': 8, 'pieceLengthM': 6, 'piecesPerBundle': 20},
        density: 7850,
        inputUnit: 'piece',
        inputValue: 1,
        overrideKgPerMetre: angle8.kgPerMetre,
      );
      expect(angleRes.totalKg, closeTo(58.2, 0.5));

      // قوطی ۴۰×۴۰ سبک (۱۴ کگ) در برابر سنگین (۱۷.۱ کگ)
      final rhsGroup = marketPresetGroups['rhs']!;
      final rhsLight = rhsGroup.lightItems.firstWhere((e) => e.id == '40x40');
      final rhsHeavy = rhsGroup.heavyItems.firstWhere((e) => e.id == '40x40');
      final resL = ProductConverter.convert(
        productId: 'rhs',
        fields: {'heightMm': 40, 'widthMm': 40, 'thicknessMm': 2, 'pieceLengthM': 6, 'piecesPerBundle': 12},
        density: 7850,
        inputUnit: 'piece',
        inputValue: 1,
        overrideKgPerMetre: rhsLight.kgPerMetre,
      );
      final resH = ProductConverter.convert(
        productId: 'rhs',
        fields: {'heightMm': 40, 'widthMm': 40, 'thicknessMm': 2, 'pieceLengthM': 6, 'piecesPerBundle': 12},
        density: 7850,
        inputUnit: 'piece',
        inputValue: 1,
        overrideKgPerMetre: rhsHeavy.kgPerMetre,
      );
      expect(resL.totalKg, closeTo(14.0, 1e-6));
      expect(resH.totalKg, closeTo(17.1, 1e-6));
      expect(resH.totalKg, greaterThan(resL.totalKg));

      // هاش ۲۰ سبک (۵۰۸) و سنگین (۷۳۶)
      final hbGroup = marketPresetGroups['hbeam']!;
      expect(hbGroup.lightItems.firstWhere((e) => e.id == '20').kgPerPiece, 508);
      expect(hbGroup.heavyItems.firstWhere((e) => e.id == '20').kgPerPiece, 736);
    });

    test('8mm 20x20cm plate, mesh 11m2, stud 19x100, wallpost kg->m, gutter m->kg & ghameh', () {
      // ورق ۸ میل ۲۰×۲۰ سانتی‌متر (= ۲۰۰×۲۰۰ میلی‌متر)
      final plate20 = ProductConverter.convert(
        productId: 'cut_plate',
        fields: {'thicknessMm': 8, 'widthMm': 200, 'lengthMm': 200, 'piecesPerBundle': 10},
        density: 7850,
        inputUnit: 'piece',
        inputValue: 1,
      );
      expect(plate20.kgPerPiece, closeTo(2.512, 1e-6));

      // توری ۱۱ مترمربع (۲ کیلو در مترمربع)
      final mesh11 = ProductConverter.convert(
        productId: 'mesh_area',
        fields: {'kgPerM2': 2.0, 'areaPerPieceM2': 2.0, 'piecesPerBundle': 10},
        density: 7850,
        inputUnit: 'm2',
        inputValue: 11,
      );
      expect(mesh11.totalAreaM2, closeTo(11, 1e-9));
      expect(mesh11.totalKg, closeTo(22, 1e-9));
      expect(mesh11.totalPieces, closeTo(5.5, 1e-9));

      // گل‌میخ ۱۹×۱۰۰ میلی‌متر (~۰.۲۶۲ کیلوگرم)
      final stud19 = ProductConverter.convert(
        productId: 'stud',
        fields: {'diameterMm': 19, 'lengthMm': 100, 'piecesPerBundle': 80},
        density: 7850,
        inputUnit: 'piece',
        inputValue: 100,
      );
      expect(stud19.kgPerPiece, closeTo(0.262, 0.015));

      // وال‌پست ورودی کیلوگرم -> متراژ و شاخه
      final wp = ProductConverter.convert(
        productId: 'wallpost',
        fields: {'thicknessMm': 2, 'widthMm': 250, 'pieceLengthM': 3, 'piecesPerBundle': 10},
        density: 7850,
        inputUnit: 'kg',
        inputValue: 392.5,
      );
      expect(wp.totalMetres, closeTo(100, 1e-6));
      expect(wp.totalPieces, closeTo(100 / 3, 1e-6));

      // آبرو متراژ -> وزن و مساحت ورق
      final gt = ProductConverter.convert(
        productId: 'gutter',
        fields: {'thicknessMm': 1, 'widthMm': 500, 'coatGsm': 0, 'pieceLengthM': 6, 'piecesPerBundle': 10},
        density: 7850,
        inputUnit: 'm',
        inputValue: 24,
      );
      expect(gt.totalPieces, closeTo(4, 1e-9));
      expect(gt.totalAreaM2, closeTo(12, 1e-9));
      expect(gt.totalKg, closeTo(94.2, 1e-6));

      // قامه میلگرد ۱۸ + متعلقات مهره و واشر
      final gh = ProductConverter.convert(
        productId: 'ghameh',
        fields: {'diameterMm': 18, 'pieceLengthM': 0.5, 'accessoriesKg': 0.1, 'piecesPerBundle': 25},
        density: 7850,
        inputUnit: 'piece',
        inputValue: 10,
      );
      expect(gh.totalMetres, closeTo(5, 1e-9));
      expect(gh.totalKg, greaterThan(10.9));
    });

    test('order pricing computes base + cut/thread-bend/punch/laser/drill services + tax/shipping', () {
      final rebar18 = ProductConverter.convert(
        productId: 'rebar',
        fields: {'diameterMm': 18, 'pieceLengthM': 12, 'piecesPerBundle': 100},
        density: 7850,
        inputUnit: 'piece',
        inputValue: 10,
      );
      final order = ProductConverter.calculateOrderCost(
        conversion: rebar18,
        basePriceUnit: 'kg',
        baseUnitPrice: 100000,
        services: const [
          OrderServiceInput(name: 'برش', unit: 'piece', unitPrice: 15000),
          OrderServiceInput(name: 'رزوه و خم', unit: 'manual', manualQuantity: 20, unitPrice: 25000),
          OrderServiceInput(name: 'پانچ', unit: 'manual', manualQuantity: 40, unitPrice: 5000),
          OrderServiceInput(name: 'لیزر', unit: 'm', unitPrice: 2000),
          OrderServiceInput(name: 'دریل', unit: 'flat', unitPrice: 100000),
        ],
        shipping: 500000,
        taxPercent: 10,
        taxIncludesServices: true,
      );
      // 10*15k + 20*25k + 40*5k + 120*2k + 100k = 150k + 500k + 200k + 240k + 100k = 1,190,000
      expect(order.servicesTotal, closeTo(1190000, 1e-6));
      expect(order.baseCost, closeTo(rebar18.totalKg * 100000, 1e-3));
      expect(order.grandTotal, closeTo((order.baseCost + 1190000) * 1.10 + 500000, 1e-2));
      expect(order.finalPerKg, greaterThan(100000));
    });

    testWidgets('ProductConverterView adds services (برش، رزوه و خم) and computes final price',
        (t) async {
      t.view.physicalSize = const Size(800, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: CalculatorPage())));
      await t.pumpAndSettle();

      final listScroll = find.byType(Scrollable).first;
      await t.scrollUntilVisible(find.text('+ برش'), 300, scrollable: listScroll);
      await t.pumpAndSettle();
      await t.tap(find.text('+ برش'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'نام خدمت'), findsOneWidget);

      await t.scrollUntilVisible(find.text('+ رزوه و خم'), 300, scrollable: listScroll);
      await t.pumpAndSettle();
      await t.tap(find.text('+ رزوه و خم'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'نام خدمت'), findsNWidgets(2));

      final priceField = find.widgetWithText(TextField, 'قیمت پایه کالا (تومان)');
      await t.scrollUntilVisible(priceField, -250, scrollable: listScroll);
      await t.pumpAndSettle();
      await t.enterText(priceField, '100000');
      await t.pumpAndSettle();

      await t.scrollUntilVisible(
          find.text('قیمت نهایی سفارش و ریز خدمات'), 300,
          scrollable: listScroll);
      expect(find.text('قیمت نهایی سفارش و ریز خدمات'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('HelpBadge (!) opens visual guide sheet without overflow',
        (t) async {
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: CalculatorPage())));
      await t.pumpAndSettle();

      final badges = find.text('!');
      expect(badges, findsWidgets);
      await t.tap(badges.first);
      await t.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.textContaining('ورق تخت'), findsWidgets);
      expect(t.takeException(), isNull);
    });

    test('convertCutPiece ignores stock dimensions when includeStockWaste is false and adds waste to price when enabled', () {
      // 10 cut plates of 300x400x2mm steel -> each = 1.884 kg, total = 18.84 kg
      final pureCut = ProductConverter.convertCutPiece(
        productId: 'plate',
        fields: {'thicknessMm': 2, 'coatGsm': 0},
        density: 7850,
        inputUnit: 'cut',
        inputValue: 10,
        cutWidthMm: 300,
        cutLengthMm: 400,
      );
      expect(pureCut.kgPerCut, closeTo(1.884, 1e-6));
      expect(pureCut.totalKg, closeTo(18.84, 1e-6));
      expect(pureCut.cutAllocation, isNull);

      final pureCost = ProductConverter.calculateOrderCost(
        conversion: pureCut,
        basePriceUnit: 'kg',
        baseUnitPrice: 100000,
      );
      expect(pureCost.baseCost, closeTo(1884000, 1));

      // Now turn ON stock sheet waste (1250x2500mm sheet = 49.0625 kg; fits 24 cuts -> 1 sheet required)
      final withStock = ProductConverter.convertCutPiece(
        productId: 'plate',
        fields: {'thicknessMm': 2, 'coatGsm': 0},
        density: 7850,
        inputUnit: 'cut',
        inputValue: 10,
        cutWidthMm: 300,
        cutLengthMm: 400,
        includeStockWaste: true,
        stockWidthMm: 1250,
        stockLengthM: 2.5,
      );
      expect(withStock.cutAllocation, isNotNull);
      expect(withStock.cutAllocation!.requiredStockPieces, 1);
      expect(withStock.cutAllocation!.stockTotalKg, closeTo(49.0625, 1e-4));
      expect(withStock.cutAllocation!.wasteKg, closeTo(30.2225, 1e-4));

      // Charging waste in base price bills full stock sheet weight (49.0625 kg)
      final wasteChargedCost = ProductConverter.calculateOrderCost(
        conversion: withStock,
        basePriceUnit: 'kg',
        baseUnitPrice: 100000,
        includeWasteInBaseCost: true,
      );
      expect(wasteChargedCost.baseQuantity, closeTo(49.0625, 1e-4));
      expect(wasteChargedCost.baseCost, closeTo(4906250, 10));
    });

    testWidgets('CutCalculatorView isolated tab switches cleanly and toggles stock waste',
        (t) async {
      t.view.physicalSize = const Size(800, 1200);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);

      await t.pumpWidget(const MaterialApp(home: Scaffold(body: CalculatorPage())));
      await t.pumpAndSettle();

      await t.tap(find.text('برش‌خورده'));
      await t.pumpAndSettle();

      expect(find.text('حالت برش‌خورده مستقل (آزمایشی)'), findsOneWidget);
      // 10 cuts of 300x400x2mm = 1.884 kg each, 18.840 kg total
      expect(find.textContaining('۱٫۸۸۴ کیلوگرم'), findsOneWidget);
      expect(find.textContaining('۱۸٫۸۴۰ کیلو'), findsOneWidget);
      // Stock sheet width is hidden while toggle is OFF
      expect(find.text('عرض ورق فابریک (میلی‌متر)'), findsNothing);

      final scroll = find.byType(Scrollable).first;
      await t.scrollUntilVisible(
        find.text('تأمین از شیت/شاخه فابریک و محاسبه پرت'),
        250,
        scrollable: scroll,
      );
      await t.tap(find.text('تأمین از شیت/شاخه فابریک و محاسبه پرت'));
      await t.pumpAndSettle();

      expect(find.text('عرض ورق فابریک (میلی‌متر)'), findsOneWidget);
      expect(find.text('اضافه شدن وزن پرت به قیمت نهایی کالا'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
