import 'package:flutter/material.dart';

enum TransitionDirection { rightToLeft, leftToRight, bottomToTop, fadeOnly }

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final TransitionDirection direction;
  final Duration transitionDurationOverride;

  SmoothPageRoute({
    required this.page,
    this.direction = TransitionDirection.rightToLeft,
    this.transitionDurationOverride = const Duration(milliseconds: 320),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: transitionDurationOverride,
          reverseTransitionDuration: transitionDurationOverride,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            if (direction == TransitionDirection.fadeOnly) {
              return FadeTransition(
                opacity: curvedAnimation,
                child: child,
              );
            }

            Offset beginOffset;
            switch (direction) {
              case TransitionDirection.rightToLeft:
                beginOffset = const Offset(0.08, 0.0);
                break;
              case TransitionDirection.leftToRight:
                beginOffset = const Offset(-0.08, 0.0);
                break;
              case TransitionDirection.bottomToTop:
                beginOffset = const Offset(0.0, 0.08);
                break;
              case TransitionDirection.fadeOnly:
                beginOffset = Offset.zero;
                break;
            }

            return SlideTransition(
              position: Tween<Offset>(
                begin: beginOffset,
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}
