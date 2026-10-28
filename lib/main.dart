import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/pos_provider.dart';
import 'providers/table_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Strictly lock orientation to portrait for optimal Android phone usage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDark = prefs.getBool('app_is_dark_mode');
      if (savedDark != null && mounted) {
        setState(() => _isDarkMode = savedDark);
      }
    } catch (_) {}
  }

  Future<void> _toggleTheme() async {
    final next = !_isDarkMode;
    setState(() {
      _isDarkMode = next;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_is_dark_mode', next);
    } catch (_) {}
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
        title: 'Rest POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: SplashScreen(
          onToggleTheme: _toggleTheme,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }
}
