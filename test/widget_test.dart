import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaurant_pos/main.dart';
import 'package:flutter_restaurant_pos/models/menu_item.dart';
import 'package:flutter_restaurant_pos/models/order_model.dart';
import 'package:flutter_restaurant_pos/models/restaurant_profile.dart';
import 'package:flutter_restaurant_pos/providers/pos_provider.dart';
import 'package:flutter_restaurant_pos/widgets/thermal_slip_preview_dialog.dart';
import 'package:flutter_restaurant_pos/core/utils/app_notification.dart';
import 'package:provider/provider.dart';


void main() {
  testWidgets('Restaurant POS smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RestaurantPosApp());
    await tester.pumpAndSettle();
    expect(find.text('Spice Garden Restaurant'), findsOneWidget);
  });

  group('PosProvider GST & Round-Off Calculations', () {
    test('Calculates 5% GST and Round-Off correctly', () {
      final pos = PosProvider();
      pos.updateProfile(const RestaurantProfile(
        isGstEnabled: true,
        gstRatePercent: 5.0,
        isRoundOffEnabled: true,
      ));

      // Add item worth ₹55.00 (5500 paise)
      const item = MenuItem(
        id: 401,
        categoryId: 4,
        name: 'Butter Naan',
        pricePaise: 5500,
      );
      pos.addToCart(item);

      // Subtotal = 5500 paise (₹55.00)
      expect(pos.subtotalPaise, 5500);
      // Tax at 5% = 5500 * 500 / 10000 = 275 paise (₹2.75)
      expect(pos.taxPaise, 275);
      // Exact total = 5500 + 275 = 5775 paise (₹57.75)
      expect(pos.exactTotalPaise, 5775);
      // Round-off to nearest ₹1 (5800 paise) = +25 paise (+₹0.25)
      expect(pos.roundOffAdjustmentPaise, 25);
      // Total payable = 5800 paise (₹58.00)
      expect(pos.totalPaise, 5800);
      expect(pos.totalRupees, 58.0);
    });

    test('Non-GST mode applies 0% tax', () {
      final pos = PosProvider();
      pos.updateProfile(const RestaurantProfile(
        isGstEnabled: false,
        isRoundOffEnabled: false,
      ));

      const item = MenuItem(
        id: 303,
        categoryId: 3,
        name: 'Butter Chicken Handi',
        pricePaise: 38000, // ₹380
      );
      pos.addToCart(item);

      expect(pos.isGstEnabled, false);
      expect(pos.taxPaise, 0);
      expect(pos.totalPaise, 38000);
    });

    test('Tax Inclusive mode splits GST without adding to total', () {
      final pos = PosProvider();
      pos.updateProfile(const RestaurantProfile(
        isGstEnabled: true,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
        isRoundOffEnabled: false,
      ));

      // Item worth ₹105.00 MRP (10500 paise)
      const item = MenuItem(
        id: 999,
        categoryId: 1,
        name: 'Beverage Special',
        pricePaise: 10500,
      );
      pos.addToCart(item);

      // Total payable remains ₹105.00
      expect(pos.isTaxInclusive, true);
      expect(pos.totalPaise, 10500);
      // Taxable base = 10500 * 10000 / 10500 = 10000 paise (₹100.00)
      expect(pos.taxableBasePaise, 10000);
      // Tax = 500 paise (₹5.00)
      expect(pos.taxPaise, 500);
    });
  });

  testWidgets('ThermalSlipPreviewDialog renders 58mm/80mm preview and print action', (WidgetTester tester) async {
    final sampleOrder = Order(
      id: 'test-ord-1',
      orderNumber: 'ORD-0099',
      type: OrderType.dineIn,
      tableName: 'T-05',
      items: [
        OrderItem(
          menuItem: const MenuItem(
            id: 101,
            categoryId: 1,
            name: 'Masala Dosa',
            pricePaise: 8000,
          ),
          quantity: 2,
          unitPricePaise: 8000,
        ),
      ],
      subtotalPaise: 16000,
      taxBps: 500,
      createdAt: DateTime(2026, 10, 28, 19, 30),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PosProvider>(
        create: (_) => PosProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: ThermalSlipPreviewDialog(
              order: sampleOrder,
              title: 'Thermal Slip Preview',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dialog header & slip elements
    expect(find.text('Thermal Slip Preview'), findsOneWidget);
    expect(find.text('58mm'), findsOneWidget);
    expect(find.text('80mm'), findsOneWidget);
    expect(find.text('#ORD-0099'), findsOneWidget);
    expect(find.text('Masala Dosa'), findsOneWidget);
    expect(find.text('Print Slip 🖨️'), findsOneWidget);
    expect(find.text('Cancel / Edit'), findsOneWidget);
  });

  testWidgets('AppNotification displays at top and dismisses', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AppNotification.showSuccess(
                    context,
                    'Operation completed successfully',
                    title: 'Backup Created',
                  );
                },
                child: const Text('Trigger Notification'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap to trigger notification
    await tester.tap(find.text('Trigger Notification'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 350)); // Settle animation

    // Verify top notification card appears
    expect(find.text('Backup Created'), findsOneWidget);
    expect(find.text('Operation completed successfully'), findsOneWidget);

    // Test dismiss
    AppNotification.dismiss();
    await tester.pump();
    expect(find.text('Operation completed successfully'), findsNothing);
  });

  testWidgets('Center FAB navigates directly to POS screen without modal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const RestaurantPosApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final addIcon = find.byIcon(Icons.add_rounded);
    expect(addIcon, findsOneWidget);

    await tester.tap(addIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Must show POS screen and NOT show Quick Actions modal
    expect(find.text('Quick Actions'), findsNothing);
    expect(find.text('POS Billing'), findsOneWidget);
  });
}

