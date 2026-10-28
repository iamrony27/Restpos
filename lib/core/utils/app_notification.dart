import 'dart:async';
import 'package:flutter/material.dart';
import '../channels/native_api_channel.dart';
import '../theme/color_schemes.dart';

enum NotificationType { success, error, info, warning }

/// High-performance animated top notification banner service.
/// Displays notifications at the top of the screen (below the status bar)
/// rather than at the bottom, preventing navigation bar overlap.
class AppNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Shows a success notification banner at the top of the screen
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Success',
      type: NotificationType.success,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Shows an error notification banner at the top of the screen
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Error',
      type: NotificationType.error,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Shows an informational notification banner at the top of the screen
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    IconData? customIcon,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      context,
      message: message,
      title: title,
      customIcon: customIcon,
      type: NotificationType.info,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Dismisses any currently active top notification immediately
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Master method to display a banner at the top of the screen
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    NotificationType type = NotificationType.info,
    IconData? customIcon,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    try {
      final overlay = Overlay.of(context);

      // Dismiss any previously active banner
      dismiss();

      // Trigger slight native haptic feedback
      NativeApiChannel.triggerNativeHaptic(type: 'click');

      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => _TopNotificationWidget(
          title: title,
          message: message,
          type: type,
          customIcon: customIcon,
          duration: duration,
          onTap: onTap,
          onDismiss: () {
            if (_currentEntry == entry) {
              dismiss();
            }
          },
        ),
      );

      _currentEntry = entry;
      overlay.insert(entry);
    } catch (_) {
      // Fallback in case overlay is unavailable in edge situations
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String? title;
  final String message;
  final NotificationType type;
  final IconData? customIcon;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    this.title,
    required this.message,
    required this.type,
    this.customIcon,
    required this.duration,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    _autoDismissTimer = Timer(widget.duration, () {
      _dismissWithAnimation();
    });
  }

  void _dismissWithAnimation() {
    if (!mounted) return;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _getAccentColor() {
    switch (widget.type) {
      case NotificationType.success:
        return CulinaryColors.emeraldGreen;
      case NotificationType.error:
        return const Color(0xFFEF4444);
      case NotificationType.warning:
        return CulinaryColors.turmericGold;
      case NotificationType.info:
        return const Color(0xFF0284C7);
    }
  }

  IconData _getIcon() {
    if (widget.customIcon != null) return widget.customIcon!;
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final accentColor = _getAccentColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF1E1E24)
        : const Color(0xFFFFFFFF);
    final textColor = isDark
        ? const Color(0xFFF9FAFB)
        : const Color(0xFF111827);
    final subtextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF4B5563);

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  // Swipe up to dismiss immediately
                  if (details.primaryDelta != null && details.primaryDelta! < -4) {
                    _dismissWithAnimation();
                  }
                },
                onTap: () {
                  widget.onTap?.call();
                  _dismissWithAnimation();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withOpacity(0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: accentColor.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Accent Icon Container
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(),
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Message
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.title != null && widget.title!.isNotEmpty) ...[
                                Text(
                                  widget.title!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: textColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: widget.title != null ? FontWeight.w500 : FontWeight.w600,
                                  color: widget.title != null ? subtextColor : textColor,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Dismiss Close Button
                        GestureDetector(
                          onTap: _dismissWithAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.04),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: subtextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
