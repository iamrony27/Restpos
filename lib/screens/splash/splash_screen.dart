import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/theme/color_schemes.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/table_provider.dart';
import '../home_shell_screen.dart';
import '../setup/setup_wizard_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SplashScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();

    // Parallelize storage preloading with branded splash animation for 2x faster cold boot
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1000)),
      posProvider.loadProfileFromStorage(),
      orderProvider.loadFromStorage(),
      tableProvider.loadFromStorage(),
      menuProvider.loadFromStorage(),
      SharedPreferences.getInstance(),
    ]);

    if (!mounted) return;

    final prefs = results[5] as SharedPreferences;
    final isSetupCompleted = prefs.getBool('is_setup_completed') ?? false;

    if (!mounted) return;

    if (!isSetupCompleted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: SetupWizardScreen(
              isInitialSetup: true,
              onToggleTheme: widget.onToggleTheme,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: HomeShellScreen(
              onToggleTheme: widget.onToggleTheme,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate Obsidian
      body: GestureDetector(
        onTap: _loadAndNavigate, // Tap to immediately skip splash
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle background ambient glow
              Positioned(
                top: MediaQuery.of(context).size.height * 0.28,
                left: MediaQuery.of(context).size.width * 0.5 - 140,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF59E0B).withOpacity(0.12),
                        const Color(0xFF0F172A).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Centered Brand Content
              Center(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App Logo Image / Emblem Container
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: const Color(0xFF1E293B),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withOpacity(0.20),
                                    blurRadius: 36,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.40),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withOpacity(0.35),
                                  width: 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/icon/splash_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) {
                                  // Elegant programmatic fallback
                                  return Container(
                                    color: const Color(0xFF0F172A),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.restaurant_rounded,
                                            size: 54,
                                            color: CulinaryColors.flameOrange,
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 32,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: Colors.white70,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 28),

                            // App Name
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'REST ',
                                    style: GoogleFonts.outfit(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'POS',
                                    style: GoogleFonts.outfit(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: CulinaryColors.restOrange,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Tagline
                            Text(
                              'Smart Restaurant Billing & Kitchen Operations',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8), // Slate 400
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Minimalist loading bar
                            SizedBox(
                              width: 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: const LinearProgressIndicator(
                                  backgroundColor: Color(0xFF1E293B),
                                  valueColor: AlwaysStoppedAnimation<Color>(CulinaryColors.restOrange),
                                  minHeight: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom version and copyright indicator
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'v1.0.0 (Production Ready)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B), // Slate 500
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offline First • Ultra-Fast • Secure',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
