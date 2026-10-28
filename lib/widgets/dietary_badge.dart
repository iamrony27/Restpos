import 'package:flutter/material.dart';
import '../models/menu_item.dart';

class DietaryBadge extends StatelessWidget {
  final DietaryType type;
  final double size;

  const DietaryBadge({
    super.key,
    required this.type,
    this.size = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Widget innerIcon;

    switch (type) {
      case DietaryType.veg:
        borderColor = const Color(0xFF16A34A); // Green
        innerIcon = Container(
          width: size * 0.55,
          height: size * 0.55,
          decoration: BoxDecoration(
            color: borderColor,
            shape: BoxShape.circle,
          ),
        );
        break;
      case DietaryType.nonVeg:
        borderColor = const Color(0xFFDC2626); // Red
        innerIcon = Container(
          width: size * 0.55,
          height: size * 0.55,
          decoration: BoxDecoration(
            color: borderColor,
            shape: BoxShape.circle,
          ),
        );
        break;
      case DietaryType.egg:
        borderColor = const Color(0xFFD97706); // Amber
        innerIcon = Container(
          width: size * 0.55,
          height: size * 0.55,
          decoration: BoxDecoration(
            color: borderColor,
            shape: BoxShape.circle,
          ),
        );
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: innerIcon,
    );
  }
}
