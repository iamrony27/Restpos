import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/channels/native_api_channel.dart';
import '../core/theme/color_schemes.dart';
import 'dashboard/dashboard_screen.dart';
import 'items/items_screen.dart';
import 'orders/orders_screen.dart';
import 'pos/pos_screen.dart';
import 'reports/sales_report_screen.dart';
import 'settings/settings_screen.dart';
import 'tables/tables_screen.dart';

class HomeShellScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeShellScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;
  bool _isBottomBarVisible = true;

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    NativeApiChannel.triggerNativeHaptic();
    setState(() {
      _currentIndex = index;
    });
  }

  bool _handleScrollNotification(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse && _isBottomBarVisible) {
      // User is scrolling down -> Hide bar
      setState(() => _isBottomBarVisible = false);
    } else if (notification.direction == ScrollDirection.forward && !_isBottomBarVisible) {
      // User is scrolling up -> Show bar
      setState(() => _isBottomBarVisible = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 720;

    final screens = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const PosScreen(),
      const ItemsScreen(),
      TablesScreen(onNavigateTab: _onTabSelected),
      const OrdersScreen(),
      SettingsScreen(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ];

    if (isTablet) {
      // Tablet / POS Counter Desktop NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabSelected,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.restaurant_rounded, color: Colors.white),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale_rounded),
                  label: Text('POS'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: Text('Items'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.table_restaurant_outlined),
                  selectedIcon: Icon(Icons.table_restaurant_rounded),
                  label: Text('Tables'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('Orders'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: screens[_currentIndex],
              ),
            ),
          ],
        ),
      );
    }

    // Phone Floating FAB-Style Rounded NavigationBar with Scroll Auto-Hide
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: _handleScrollNotification,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 1.4),
        child: SafeArea(
          child: Container(
            height: 68,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: widget.isDarkMode
                      ? Colors.black.withOpacity(0.55)
                      : const Color(0xFF2E1A11).withOpacity(0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: CulinaryColors.flameOrange.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? const Color(0xFF141210).withOpacity(0.92)
                        : const Color(0xFF261D19).withOpacity(0.94),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: CulinaryColors.flameOrange.withOpacity(0.28),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
                      _buildNavItem(2, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Items'),
                      _buildCenterAddButton(),
                      _buildNavItem(3, Icons.table_restaurant_outlined, Icons.table_restaurant_rounded, 'Tables'),
                      _buildNavItem(4, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? CulinaryColors.flameOrange : const Color(0xFFBDB3AC);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabSelected(index),
          splashColor: CulinaryColors.flameOrange.withOpacity(0.12),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CulinaryColors.flameOrange.withOpacity(0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? filledIcon : outlineIcon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    final isPosSelected = _currentIndex == 1;
    return GestureDetector(
      onTap: () => _showQuickActionsModal(context),
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isPosSelected
                ? [CulinaryColors.flameOrange, CulinaryColors.flameOrange]
                : [CulinaryColors.flameOrange, CulinaryColors.tandoorSpice],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: isPosSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: CulinaryColors.flameOrange.withOpacity(isPosSelected ? 0.6 : 0.42),
              blurRadius: isPosSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _showQuickActionsModal(BuildContext context) {
    NativeApiChannel.triggerNativeHaptic();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1A17) : const Color(0xFFFFFBF7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? Colors.white12 : CulinaryColors.flameOrange.withOpacity(0.2),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Fast navigation & billing operations',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildQuickActionTile(
                ctx,
                title: 'New POS Billing',
                subtitle: 'Open terminal to enter customer items & print receipt',
                icon: Icons.point_of_sale_rounded,
                color: CulinaryColors.flameOrange,
                onTap: () {
                  Navigator.pop(ctx);
                  _onTabSelected(1);
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                ctx,
                title: 'Manage Dishes & Menu',
                subtitle: 'Add new food item, update price or stock status',
                icon: Icons.restaurant_menu_rounded,
                color: CulinaryColors.emeraldGreen,
                onTap: () {
                  Navigator.pop(ctx);
                  _onTabSelected(2);
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                ctx,
                title: 'Table Seating & Status',
                subtitle: 'View live floor layout, occupied and billed tables',
                icon: Icons.table_restaurant_rounded,
                color: CulinaryColors.royalBlue,
                onTap: () {
                  Navigator.pop(ctx);
                  _onTabSelected(3);
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                ctx,
                title: 'Live Kitchen Orders (KOT)',
                subtitle: 'Check order ticket queue, settle active bills',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(ctx);
                  _onTabSelected(4);
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                ctx,
                title: 'Sales & GST Tax PDF Reports',
                subtitle: 'Generate monthly/quarterly tax audit statements',
                icon: Icons.picture_as_pdf_rounded,
                color: CulinaryColors.tandoorSpice,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesReportScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext ctx, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF26211E)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.colorScheme.outline.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
