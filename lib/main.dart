import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/pos_provider.dart';
import 'providers/table_provider.dart';
import 'screens/home_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge to edge Android system UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const RestaurantPosApp());
}

class RestaurantPosApp extends StatefulWidget {
  const RestaurantPosApp({super.key});

  @override
  State<RestaurantPosApp> createState() => _RestaurantPosAppState();
}

class _RestaurantPosAppState extends State<RestaurantPosApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PosProvider()),
      ],
      child: MaterialApp(
        title: 'Spice Garden POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: HomeShellScreen(
          onToggleTheme: _toggleTheme,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }
}
