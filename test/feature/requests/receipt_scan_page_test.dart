import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_essentials_mobile/features/requests/presentation/pages/receipt_scan_page.dart';

void main() {
  testWidgets('ReceiptScanPage renders scanner and processes sample receipt with restock action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ReceiptScanPage(),
      ),
    );

    // Initial scanner state
    expect(find.text('Receipt Scanner (OCR)'), findsOneWidget);
    expect(find.text('Optical Receipt Scanning'), findsOneWidget);
    expect(find.text('Scan Store Receipt with Camera'), findsOneWidget);
    expect(find.text('Scan Sample Errand Receipt'), findsOneWidget);

    // Tap sample errand receipt button
    await tester.tap(find.text('Scan Sample Errand Receipt'));
    await tester.pump(); // Starts loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Running OCR text extraction…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verifies parsed overview
    expect(find.text('Target - Supercenter'), findsOneWidget);
    expect(find.text('Total Paid'), findsOneWidget);
    expect(find.text(r'$42.87'), findsOneWidget);
    expect(find.text('Automatically recorded to Household Ledger'), findsOneWidget);

    // Verifies pantry restock suggestions
    expect(find.text('Auto-Matched Pantry Essentials'), findsOneWidget);
    expect(find.text('Organic Whole Milk'), findsOneWidget);
    expect(find.text('Grade A Eggs'), findsOneWidget);

    // Verifies line items
    expect(find.text('Receipt Line Items (4)'), findsOneWidget);
    expect(find.text('Organic Whole Milk 1 Gallon'), findsOneWidget);
    expect(find.text('Grade A Large Eggs 12pk'), findsOneWidget);

    // Tap Restock button on first suggested item
    final restockButtons = find.text('Restock (+1)');
    expect(restockButtons, findsNWidgets(2));
    await tester.tap(restockButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Restocked ✓'), findsOneWidget);
    expect(find.text('Pantry stock replenished (+1)'), findsOneWidget);
  });
}
