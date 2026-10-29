import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaurant_pos/main.dart';
import 'package:flutter_restaurant_pos/models/menu_item.dart';
import 'package:flutter_restaurant_pos/models/order_model.dart';
import 'package:flutter_restaurant_pos/models/restaurant_profile.dart';
import 'package:flutter_restaurant_pos/providers/pos_provider.dart';
import 'package:flutter_restaurant_pos/widgets/thermal_slip_preview_dialog.dart';
import 'package:flutter_restaurant_pos/core/utils/app_notification.dart';
import 'package:flutter_restaurant_pos/models/table_model.dart';
import 'package:flutter_restaurant_pos/providers/table_provider.dart';
import 'package:flutter_restaurant_pos/providers/order_provider.dart';
import 'package:provider/provider.dart';


import 'package:flutter_restaurant_pos/models/menu_category.dart';
import 'package:flutter_restaurant_pos/core/utils/currency_formatter.dart';
import 'package:flutter_restaurant_pos/core/utils/upi_helper.dart';
import 'package:flutter_restaurant_pos/services/report_pdf_service.dart';
import 'package:flutter_restaurant_pos/services/backup_restore_service.dart';
import 'package:flutter_restaurant_pos/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'is_setup_completed': true});
  });

  testWidgets('Fresh install shows SetupWizardScreen when is_setup_completed is false', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'is_setup_completed': false});
    await tester.pumpWidget(const RestaurantPosApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Rest POS'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Restaurant POS smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'is_setup_completed': true});
    await tester.pumpWidget(const RestaurantPosApp());
    await tester.pumpAndSettle();
    expect(find.text('Rest POS'), findsWidgets);
  });

  group('PosProvider GST & Round-Off Calculations', () {
    test('Calculates 5% GST and Round-Off correctly', () {
      final pos = PosProvider();
      pos.updateProfile(const RestaurantProfile(
        isGstEnabled: true,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
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
    await tester.pumpAndSettle();

    final addIcon = find.byIcon(Icons.add_rounded);
    expect(addIcon, findsOneWidget);

    await tester.tap(addIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Must show POS screen and NOT show Quick Actions modal
    expect(find.text('Quick Actions'), findsNothing);
    expect(find.text('POS Billing'), findsOneWidget);
  });

  test('TableProvider supports add, update, and delete table operations', () {
    final tableProvider = TableProvider();
    final initialCount = tableProvider.tables.length;

    // Add table
    tableProvider.addTable(name: 'VIP Lounge', seatingCapacity: 10);
    expect(tableProvider.tables.length, equals(initialCount + 1));
    final addedTable = tableProvider.tables.last;
    expect(addedTable.name, equals('VIP Lounge'));
    expect(addedTable.seatingCapacity, equals(10));
    expect(addedTable.status, equals(TableStatus.available));

    // Update table
    tableProvider.updateTable(addedTable.id, name: 'VIP Rooftop Lounge', seatingCapacity: 12);
    final updatedTable = tableProvider.getTableById(addedTable.id);
    expect(updatedTable?.name, equals('VIP Rooftop Lounge'));
    expect(updatedTable?.seatingCapacity, equals(12));

    // Delete table
    tableProvider.deleteTable(addedTable.id);
    expect(tableProvider.tables.length, equals(initialCount));
    expect(tableProvider.getTableById(addedTable.id), isNull);
  });

  test('OrderProvider supports edit, delete, and restore order with table sync', () {
    final orderProvider = OrderProvider();
    final tableProvider = TableProvider();

    final testOrder = Order(
      id: 'test-1001',
      orderNumber: 'ORD-1001',
      type: OrderType.dineIn,
      tableId: 2,
      tableName: 'Table 2',
      status: OrderStatus.open,
      items: [
        OrderItem(
          menuItem: const MenuItem(id: 301, categoryId: 3, name: 'Paneer Butter Masala', pricePaise: 31000),
          quantity: 2,
          unitPricePaise: 31000,
        ),
      ],
      subtotalPaise: 62000,
      taxBps: 500,
      discountPaise: 0,
      createdAt: DateTime.now(),
    );
    orderProvider.addOrder(testOrder);
    tableProvider.occupyTable(2, 1001, 62000);

    // Pick an active dine-in order
    final activeOrder = orderProvider.activeOrders.first;
    final orderId = activeOrder.id;

    // 1. Test Edit Order
    final updatedItems = [
      activeOrder.items.first.copyWith(quantity: activeOrder.items.first.quantity + 2),
    ];
    orderProvider.editOrder(
      orderId,
      items: updatedItems,
      tableProvider: tableProvider,
    );

    final editedOrder = orderProvider.orders.firstWhere((o) => o.id == orderId);
    expect(editedOrder.isEdited, isTrue);
    expect(editedOrder.editedAt, isNotNull);
    expect(editedOrder.items.first.quantity, equals(updatedItems.first.quantity));

    // 2. Test Delete Order
    final initialActiveCount = orderProvider.activeOrders.length;
    final initialDeletedCount = orderProvider.deletedOrders.length;

    orderProvider.deleteOrder(orderId, tableProvider: tableProvider);

    // Should no longer be in activeOrders or standard orders list
    expect(orderProvider.orders.any((o) => o.id == orderId), isFalse);
    expect(orderProvider.activeOrders.length, equals(initialActiveCount - 1));
    expect(orderProvider.deletedOrders.length, equals(initialDeletedCount + 1));

    final deletedOrder = orderProvider.deletedOrders.firstWhere((o) => o.id == orderId);
    expect(deletedOrder.isDeleted, isTrue);
    expect(deletedOrder.deletedAt, isNotNull);
    expect(deletedOrder.status, equals(OrderStatus.cancelled));

    // 3. Test Restore Order
    orderProvider.restoreOrder(orderId);
    expect(orderProvider.orders.any((o) => o.id == orderId), isTrue);
    expect(orderProvider.deletedOrders.any((o) => o.id == orderId), isFalse);

    // 4. Test Production Reset / Clear All Orders
    orderProvider.clearAllOrders(tableProvider: tableProvider);
    expect(orderProvider.orders.isEmpty, isTrue);
    expect(tableProvider.occupiedCount, equals(0));
    expect(tableProvider.billedCount, equals(0));
  });

  test('LocalStorageService persists and restores profile and menu items', () async {
    SharedPreferences.setMockInitialValues({});

    const profile = RestaurantProfile(
      name: 'Spice Garden',
      phone: '9876543210',
      isTaxInclusive: true,
      gstRatePercent: 5.0,
    );
    await LocalStorageService.saveProfile(profile);
    final loadedProfile = await LocalStorageService.loadProfile();
    expect(loadedProfile, isNotNull);
    expect(loadedProfile!.name, equals('Spice Garden'));
    expect(loadedProfile.isTaxInclusive, isTrue);

    const customItem = MenuItem(
      id: 9999,
      categoryId: 0,
      name: 'Chef Special Kheer',
      pricePaise: 12000,
      dietaryType: DietaryType.veg,
    );
    await LocalStorageService.saveMenuItems([customItem]);
    final loadedItems = await LocalStorageService.loadMenuItems();
    expect(loadedItems, isNotNull);
    expect(loadedItems!.length, equals(1));
    expect(loadedItems.first.name, equals('Chef Special Kheer'));
    expect(loadedItems.first.pricePaise, equals(12000));
  });

  group('UpiHelper Bharat QR Generation', () {
    test('Builds valid standard UPI payment URI string', () {
      final uri = UpiHelper.buildUpiQrString(
        upiId: 'merchant@upi',
        payeeName: 'Rest POS Cafe',
        amountRupees: 250.50,
        orderNumber: 'ORD-101',
      );
      expect(uri, contains('upi://pay?'));
      expect(uri, contains('pa=merchant%40upi'));
      expect(uri, contains('pn=Rest%20POS%20Cafe'));
      expect(uri, contains('am=250.50'));
      expect(uri, contains('cu=INR'));
      expect(uri, contains('tn=Bill%20ORD-101'));
    });
  });

  group('CurrencyFormatter Exact Formatting', () {
    test('Formats integer amounts without decimal zeroes', () {
      expect(CurrencyFormatter.formatPaise(10000), equals('₹100'));
      expect(CurrencyFormatter.formatRupees(250.0), equals('₹250'));
    });

    test('Formats fractional amounts with 2 decimal places', () {
      expect(CurrencyFormatter.formatPaise(10050), equals('₹100.50'));
      expect(CurrencyFormatter.formatRupees(250.75), equals('₹250.75'));
    });
  });

  group('ReportPdfService PDF Synthesis', () {
    test('Generates valid non-empty A4 Sales & GST Report PDF bytes', () async {
      const profile = RestaurantProfile(
        name: 'The Grand Tandoor',
        tagline: 'Authentic Indian Cuisine',
        gstin: '07AAAAA0000A1Z5',
        fssai: '10019011000555',
        phone: '9876543210',
        address: 'Connaught Place, New Delhi',
        isGstEnabled: true,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
      );

      final pdfBytes = await ReportPdfService.generateSalesReportBytes(
        profile: profile,
        periodType: 'Monthly',
        periodName: 'October 2026',
        totalOrders: 42,
        grossSalesRupees: 15420.0,
        taxableBaseRupees: 14685.71,
        cgstRupees: 367.14,
        sgstRupees: 367.14,
        totalGstRupees: 734.28,
        roundOffRupees: 0.0,
        netRevenueRupees: 15420.0,
        isTaxInclusive: true,
        categorySales: {
          'Main Course': 8500.0,
          'Starters': 4200.0,
          'Beverages': 2720.0,
        },
        paymentBreakdown: {
          'UPI (Bharat QR)': 10200.0,
          'Cash Tender': 3820.0,
          'Debit / Credit Card': 1400.0,
        },
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
      // PDF standard magic bytes: %PDF-
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });
  });

  group('BackupData Serialization & Roundtrip', () {
    test('Correctly serializes and deserializes database backup', () {
      const profile = RestaurantProfile(name: 'Rest POS Test Cafe', gstin: '27ABCDE1234F1Z5');
      final categories = [const MenuCategory(id: 1, name: 'Breads', sortOrder: 1)];
      final items = [const MenuItem(id: 101, categoryId: 1, name: 'Garlic Naan', pricePaise: 6000)];
      final tables = [const RestaurantTable(id: 1, name: 'T-01', seatingCapacity: 4)];
      final orders = [
        Order(
          id: 'ord-1',
          orderNumber: 'ORD-0001',
          type: OrderType.dineIn,
          status: OrderStatus.paid,
          items: [OrderItem(menuItem: items.first, quantity: 2, unitPricePaise: 6000)],
          subtotalPaise: 12000,
          taxBps: 500,
          createdAt: DateTime(2026, 10, 29),
        ),
      ];

      final original = BackupData(
        version: 1,
        exportedAt: '2026-10-29T10:00:00.000Z',
        profile: profile,
        categories: categories,
        items: items,
        tables: tables,
        orders: orders,
      );

      final jsonStr = original.toJsonString();
      expect(jsonStr, contains('Rest POS Test Cafe'));
      expect(jsonStr, contains('Garlic Naan'));
      expect(jsonStr, contains('ORD-0001'));

      final restored = BackupData.fromJsonString(jsonStr);
      expect(restored.version, equals(1));
      expect(restored.profile.name, equals('Rest POS Test Cafe'));
      expect(restored.categories.length, equals(1));
      expect(restored.categories.first.name, equals('Breads'));
      expect(restored.items.length, equals(1));
      expect(restored.items.first.name, equals('Garlic Naan'));
      expect(restored.tables.length, equals(1));
      expect(restored.tables.first.name, equals('T-01'));
      expect(restored.orders.length, equals(1));
      expect(restored.orders.first.orderNumber, equals('ORD-0001'));
    });

    test('BackupRestoreService exports to and imports from SharedPreferences mirror seamlessly', () async {
      SharedPreferences.setMockInitialValues({});
      const profile = RestaurantProfile(name: 'SharedPreferences Cafe', gstin: '27ABCDE1234F1Z5');
      final categories = [const MenuCategory(id: 1, name: 'Main', sortOrder: 1)];
      final items = [const MenuItem(id: 101, categoryId: 1, name: 'Paneer Butter Masala', pricePaise: 24000)];
      final tables = [const RestaurantTable(id: 1, name: 'Table 1', seatingCapacity: 4)];
      final orders = <Order>[];

      await BackupRestoreService.exportBackup(
        profile: profile,
        categories: categories,
        items: items,
        tables: tables,
        orders: orders,
      );

      // Verify SharedPreferences mirror
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(BackupRestoreService.prefKeyBackupJson), isNotNull);
      expect(prefs.getString(BackupRestoreService.prefKeyBackupJson), contains('SharedPreferences Cafe'));

      // Verify hasExistingBackup returns true
      final hasBackup = await BackupRestoreService.hasExistingBackup();
      expect(hasBackup, isTrue);

      // Verify getExistingBackupInfo returns parsed metadata
      final info = await BackupRestoreService.getExistingBackupInfo();
      expect(info, isNotNull);
      expect(info!.restaurantName, equals('SharedPreferences Cafe'));
      expect(info.dishCount, equals(1));
      expect(info.categoryCount, equals(1));
      expect(info.tableCount, equals(1));

      // Verify importBackup returns correct data
      final restored = await BackupRestoreService.importBackup();
      expect(restored, isNotNull);
      expect(restored!.profile.name, equals('SharedPreferences Cafe'));
      expect(restored.items.first.name, equals('Paneer Butter Masala'));
    });
  });

  group('OrderProvider Completed Orders vs Active Unpaid Orders', () {
    test('Items sold and revenue only count paid/completed orders', () {
      final orderProvider = OrderProvider();
      expect(orderProvider.itemsSoldToday, equals(0));
      expect(orderProvider.totalRevenueRupees, equals(0.0));

      const dish = MenuItem(id: 501, categoryId: 1, name: 'Paneer Tikka', pricePaise: 25000);

      // 1. Open order (still dining, unpaid)
      final openOrder = Order(
        id: 'open-1',
        orderNumber: 'ORD-OPEN-1',
        type: OrderType.dineIn,
        status: OrderStatus.open,
        items: [OrderItem(menuItem: dish, quantity: 2, unitPricePaise: 25000)],
        subtotalPaise: 50000,
        createdAt: DateTime.now(),
      );
      orderProvider.addOrder(openOrder);

      // Open orders must NOT count as items sold or revenue
      expect(orderProvider.activeOrders.length, equals(1));
      expect(orderProvider.completedOrders.length, equals(0));
      expect(orderProvider.itemsSoldToday, equals(0));
      expect(orderProvider.totalRevenueRupees, equals(0.0));

      // 2. Mark order as completed / paid with Cash
      orderProvider.updateOrderStatus('open-1', OrderStatus.completed, method: PaymentMethod.cash);

      // Now it must be counted
      expect(orderProvider.activeOrders.length, equals(0));
      expect(orderProvider.completedOrders.length, equals(1));
      expect(orderProvider.itemsSoldToday, equals(2));
      expect(orderProvider.totalRevenueRupees, equals(525.0)); // 500 + 5% GST = 525
      expect(orderProvider.paymentDistribution[PaymentMethod.cash], equals(525.0));
    });
  });
}



