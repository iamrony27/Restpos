import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaurant_pos/models/menu_item.dart';
import 'package:flutter_restaurant_pos/models/order_model.dart';
import 'package:flutter_restaurant_pos/models/restaurant_profile.dart';
import 'package:flutter_restaurant_pos/models/table_model.dart';
import 'package:flutter_restaurant_pos/providers/pos_provider.dart';
import 'package:flutter_restaurant_pos/providers/table_provider.dart';
import 'package:flutter_restaurant_pos/providers/order_provider.dart';

void main() {
  group('Comprehensive Accounting & Statutory Tax Tests', () {
    test('Tax Inclusive and Tax Exclusive mathematical consistency', () {
      // Scenario: A dish with MRP ₹105.00 at 5% GST rate.
      // In Tax Inclusive mode: Price is ₹105.00 -> Base is ₹100.00, Tax is ₹5.00.
      final posInclusive = PosProvider();
      posInclusive.updateProfile(const RestaurantProfile(
        isGstEnabled: true,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
        isRoundOffEnabled: false,
      ));

      const item105 = MenuItem(id: 1, categoryId: 1, name: 'Special Thali', pricePaise: 10500);
      posInclusive.addToCart(item105);

      expect(posInclusive.subtotalPaise, equals(10500));
      expect(posInclusive.taxableBasePaise, equals(10000));
      expect(posInclusive.taxPaise, equals(500));
      expect(posInclusive.exactTotalPaise, equals(10500));
      expect(posInclusive.totalPaise, equals(10500));
      expect(posInclusive.taxableBasePaise + posInclusive.taxPaise, equals(posInclusive.totalPaise));

      // Scenario: A dish with base ₹100.00 at 5% GST rate in Tax Exclusive mode.
      // Base is ₹100.00 + 5% GST ₹5.00 -> Total ₹105.00.
      final posExclusive = PosProvider();
      posExclusive.updateProfile(const RestaurantProfile(
        isGstEnabled: true,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
        isRoundOffEnabled: false,
      ));

      const item100 = MenuItem(id: 2, categoryId: 1, name: 'Base Thali', pricePaise: 10000);
      posExclusive.addToCart(item100);

      expect(posExclusive.subtotalPaise, equals(10000));
      expect(posExclusive.taxableBasePaise, equals(10000));
      expect(posExclusive.taxPaise, equals(500));
      expect(posExclusive.exactTotalPaise, equals(10500));
      expect(posExclusive.totalPaise, equals(10500));
      expect(posExclusive.taxableBasePaise + posExclusive.taxPaise, equals(posExclusive.totalPaise));
    });

    test('Round-off adjustments at edge boundaries (49 paise vs 50 paise)', () {
      final pos = PosProvider();
      pos.updateProfile(const RestaurantProfile(
        isGstEnabled: false,
        isRoundOffEnabled: true,
      ));

      // 1. ₹99.49 (9949 paise) -> Should round DOWN to ₹99.00 (-49 paise adjustment)
      const item49 = MenuItem(id: 3, categoryId: 1, name: 'Item 49', pricePaise: 9949);
      pos.addToCart(item49);
      expect(pos.exactTotalPaise, equals(9949));
      expect(pos.roundOffAdjustmentPaise, equals(-49));
      expect(pos.totalPaise, equals(9900));
      expect(pos.totalRupees, equals(99.0));

      // 2. Clear and test ₹99.50 (9950 paise) -> Should round UP to ₹100.00 (+50 paise adjustment)
      pos.clearCart();
      const item50 = MenuItem(id: 4, categoryId: 1, name: 'Item 50', pricePaise: 9950);
      pos.addToCart(item50);
      expect(pos.exactTotalPaise, equals(9950));
      expect(pos.roundOffAdjustmentPaise, equals(50));
      expect(pos.totalPaise, equals(10000));
      expect(pos.totalRupees, equals(100.0));

      // 3. Clear and test ₹99.51 (9951 paise) -> Should round UP to ₹100.00 (+49 paise adjustment)
      pos.clearCart();
      const item51 = MenuItem(id: 5, categoryId: 1, name: 'Item 51', pricePaise: 9951);
      pos.addToCart(item51);
      expect(pos.exactTotalPaise, equals(9951));
      expect(pos.roundOffAdjustmentPaise, equals(49));
      expect(pos.totalPaise, equals(10000));
      expect(pos.totalRupees, equals(100.0));
    });

    test('Multiple GST slabs (0%, 5%, 12%, 18%) calculate accurately', () {
      for (final slab in [0.0, 5.0, 12.0, 18.0]) {
        final pos = PosProvider();
        pos.updateProfile(RestaurantProfile(
          isGstEnabled: slab > 0,
          gstRatePercent: slab,
          isTaxInclusive: false,
          isRoundOffEnabled: false,
        ));

        const baseItem = MenuItem(id: 10, categoryId: 1, name: 'Test Food', pricePaise: 20000); // ₹200.00
        pos.addToCart(baseItem);

        final expectedTaxPaise = ((20000 * slab) / 100).round();
        expect(pos.taxPaise, equals(expectedTaxPaise));
        expect(pos.totalPaise, equals(20000 + expectedTaxPaise));
      }
    });

    test('Discounts correctly reduce taxable base before GST calculation', () {
      final pos = PosProvider();
      pos.updateProfile(const RestaurantProfile(
        isGstEnabled: true,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
        isRoundOffEnabled: false,
      ));

      // Subtotal ₹200.00 (20000 paise)
      const item = MenuItem(id: 20, categoryId: 1, name: 'Combo Meal', pricePaise: 20000);
      pos.addToCart(item);

      // Apply ₹50.00 (5000 paise) discount
      pos.setDiscountPaise(5000);

      // Taxable base must be ₹150.00 (15000 paise)
      expect(pos.taxableBasePaise, equals(15000));
      // 5% GST on ₹150 = ₹7.50 (750 paise)
      expect(pos.taxPaise, equals(750));
      // Exact total = ₹150 + ₹7.50 = ₹157.50 (15750 paise)
      expect(pos.exactTotalPaise, equals(15750));
    });
  });

  group('Full Table Lifecycle State Synchronization', () {
    test('Transitions from Available -> Occupied -> Billed -> Available', () {
      final tableProvider = TableProvider();
      final orderProvider = OrderProvider();

      final table = tableProvider.tables.first;
      final tableId = table.id;

      // Initial state: Available
      expect(table.status, equals(TableStatus.available));

      // 1. Customer sits and places an order -> Table becomes Occupied
      final order = Order(
        id: 'ord-table-1',
        orderNumber: 'ORD-T1',
        type: OrderType.dineIn,
        tableId: tableId,
        tableName: table.name,
        status: OrderStatus.open,
        items: [
          OrderItem(
            menuItem: const MenuItem(id: 1, categoryId: 1, name: 'Biryani', pricePaise: 22000),
            quantity: 2,
            unitPricePaise: 22000,
          ),
        ],
        subtotalPaise: 44000,
        taxBps: 500,
        createdAt: DateTime.now(),
      );
      orderProvider.addOrder(order);
      tableProvider.occupyTable(tableId, 1, order.totalPaise);

      final occupiedTable = tableProvider.getTableById(tableId)!;
      expect(occupiedTable.status, equals(TableStatus.occupied));
      expect(occupiedTable.currentBillPaise, equals(order.totalPaise));

      // 2. Bill printed -> Table becomes Billed
      tableProvider.markBilled(tableId, order.totalPaise);
      orderProvider.updateOrderStatus(order.id, OrderStatus.billed);

      final billedTable = tableProvider.getTableById(tableId)!;
      expect(billedTable.status, equals(TableStatus.billed));

      // 3. Customer pays cash -> Table released back to Available
      orderProvider.updateOrderStatus(order.id, OrderStatus.completed, method: PaymentMethod.cash);
      tableProvider.freeTable(tableId);

      final availableTable = tableProvider.getTableById(tableId)!;
      expect(availableTable.status, equals(TableStatus.available));
      expect(availableTable.currentBillPaise, equals(0));
      expect(availableTable.activeOrderId, isNull);
    });
  });
}
