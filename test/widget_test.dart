import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaurant_pos/main.dart';
import 'package:flutter_restaurant_pos/models/menu_item.dart';
import 'package:flutter_restaurant_pos/models/restaurant_profile.dart';
import 'package:flutter_restaurant_pos/providers/pos_provider.dart';

void main() {
  testWidgets('Restaurant POS smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RestaurantPosApp());
    await tester.pumpAndSettle();
    expect(find.text('Spice Garden Restaurant'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Top Selling Items'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Top Selling Items'), findsOneWidget);
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
}
