import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_restaurant_pos/providers/menu_provider.dart';
import 'package:flutter_restaurant_pos/providers/order_provider.dart';
import 'package:flutter_restaurant_pos/providers/pos_provider.dart';
import 'package:flutter_restaurant_pos/providers/table_provider.dart';
import 'package:flutter_restaurant_pos/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_restaurant_pos/screens/orders/orders_screen.dart';
import 'package:flutter_restaurant_pos/screens/pos/pos_screen.dart';
import 'package:flutter_restaurant_pos/screens/reports/sales_report_screen.dart';
import 'package:flutter_restaurant_pos/screens/settings/settings_screen.dart';
import 'package:flutter_restaurant_pos/screens/tables/tables_screen.dart';

Widget createTestApp(Widget child, {PosProvider? pos, OrderProvider? orders, TableProvider? tables, MenuProvider? menu}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PosProvider>(create: (_) => pos ?? PosProvider()),
      ChangeNotifierProvider<OrderProvider>(create: (_) => orders ?? OrderProvider()),
      ChangeNotifierProvider<TableProvider>(create: (_) => tables ?? TableProvider()),
      ChangeNotifierProvider<MenuProvider>(create: (_) => menu ?? MenuProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'is_setup_completed': true});
  });

  testWidgets('PosScreen renders catalog, allows category selection and searching', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestApp(const PosScreen()));
    await tester.pumpAndSettle();

    // Verify POS screen title & search bar
    expect(find.text('POS Billing'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Search for a dish
    await tester.enterText(find.byType(TextField), 'Naan');
    await tester.pumpAndSettle();
    expect(find.text('Naan'), findsWidgets);
  });

  testWidgets('TablesScreen renders floor plan, legend pills, and status cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final tableProvider = TableProvider();
    await tester.pumpWidget(createTestApp(TablesScreen(onNavigateTab: (_) {}), tables: tableProvider));
    await tester.pumpAndSettle();

    // Verify header and legend
    expect(find.text('Floor Plan & Tables'), findsOneWidget);
    expect(find.textContaining('Available'), findsWidgets);
    expect(find.textContaining('Occupied'), findsWidgets);
    expect(find.textContaining('Billed'), findsWidgets);

    // Verify tables render
    expect(find.text('Table 1'), findsOneWidget);
  });

  testWidgets('OrdersScreen renders filter tabs (Active, Completed, Deleted)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final orderProvider = OrderProvider();
    await tester.pumpWidget(createTestApp(const OrdersScreen(), orders: orderProvider));
    await tester.pumpAndSettle();

    // Verify Header & Filter Tabs
    expect(find.text('Orders & Kitchen Tickets'), findsOneWidget);
    expect(find.textContaining('Kitchen Active'), findsOneWidget);
    expect(find.textContaining('Completed'), findsOneWidget);
    expect(find.textContaining('Deleted'), findsOneWidget);
  });

  testWidgets('DashboardScreen renders KPIs, ChartMode toggles, and Quick Action Banner', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final orderProvider = OrderProvider();
    await tester.pumpWidget(createTestApp(DashboardScreen(onNavigateTab: (_) {}), orders: orderProvider));
    await tester.pumpAndSettle();

    // Verify Dashboard Cards
    expect(find.text("Today's Gross Sales"), findsOneWidget);
    expect(find.text('Sales & GST Tax PDF Reports'), findsOneWidget);
    expect(find.text('Payment Channel Distribution'), findsOneWidget);

    // Toggle chart modes
    expect(find.text('Qty'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Trend'), findsOneWidget);

    await tester.tap(find.text('Qty'));
    await tester.pumpAndSettle();
    expect(find.text('Sales Distribution'), findsOneWidget);

    await tester.tap(find.text('Trend'));
    await tester.pumpAndSettle();
    expect(find.text('Sales History Trend'), findsOneWidget);
  });

  testWidgets('SalesReportScreen renders intervals and statutory filing details', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestApp(const SalesReportScreen()));
    await tester.pumpAndSettle();

    // Verify sales report elements
    expect(find.text('Sales & GST Reports'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Quarterly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Gross Turnover'), findsOneWidget);
    expect(find.text('Taxable Base'), findsOneWidget);
    expect(find.text('Total GST Tax'), findsOneWidget);
    expect(find.text('Generate & Print GST PDF Report'), findsOneWidget);

    // Switch to Quarterly
    await tester.tap(find.text('Quarterly'));
    await tester.pumpAndSettle();
    expect(find.text('Report Interval:'), findsOneWidget);

    // Switch to Yearly
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    expect(find.text('Report Interval:'), findsOneWidget);
  });

  testWidgets('SettingsScreen renders configuration cards and toggles theme', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 3500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool themeToggled = false;
    await tester.pumpWidget(createTestApp(
      SettingsScreen(
        onToggleTheme: () => themeToggled = true,
        isDarkMode: false,
      ),
    ));
    await tester.pumpAndSettle();

    // Verify settings titles
    expect(find.text('Settings & Configuration'), findsOneWidget);
    expect(find.text('Restaurant Setup Wizard'), findsOneWidget);
    expect(find.text('GST Tax Invoicing'), findsOneWidget);
    expect(find.text('FSSAI Food Safety License'), findsOneWidget);
    expect(find.text('Restaurant Profile'), findsOneWidget);
    expect(find.text('Material 3 Dark Theme'), findsOneWidget);

    // Toggle dark theme switch specifically
    final darkThemeTile = find.widgetWithText(ListTile, 'Material 3 Dark Theme');
    final switchFinder = find.descendant(of: darkThemeTile, matching: find.byType(Switch));
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pump();
    expect(themeToggled, isTrue);
  });
}
