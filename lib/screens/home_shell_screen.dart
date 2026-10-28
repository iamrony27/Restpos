import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/channels/native_api_channel.dart';
import '../core/theme/color_schemes.dart';
import 'dashboard/dashboard_screen.dart';
import 'items/items_screen.dart';
import 'orders/orders_screen.dart';
import 'pos/pos_screen.dart';
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
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
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
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 1.4),
        child: SafeArea(
          child: SizedBox(
            height: 82,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Bottom bar pill
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 8,
                  child: Container(
                    height: 64,
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
                              const SizedBox(width: 58), // Space for floating center FAB
                              _buildNavItem(3, Icons.table_restaurant_outlined, Icons.table_restaurant_rounded, 'Tables'),
                              _buildNavItem(4, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Elevated Floating Center FAB
                Positioned(
                  bottom: 18,
                  child: _buildCenterAddButton(),
                ),
              ],
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
    final haloColor = widget.isDarkMode ? const Color(0xFF141210) : const Color(0xFF261D19);

    return GestureDetector(
      onTap: () => _onTabSelected(1),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: haloColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CulinaryColors.flameOrange.withOpacity(isPosSelected ? 0.65 : 0.38),
              blurRadius: isPosSelected ? 18 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: isPosSelected ? 56 : 52,
          height: isPosSelected ? 56 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isPosSelected
                  ? [CulinaryColors.flameOrange, const Color(0xFFFF7A00)]
                  : [CulinaryColors.flameOrange, CulinaryColors.tandoorSpice],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isPosSelected ? Colors.white : Colors.white.withOpacity(0.4),
              width: isPosSelected ? 2.4 : 1.4,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

}

