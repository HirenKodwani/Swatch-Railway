import 'package:flutter/material.dart';
import '../../../../utills/app_colors.dart';

class GradeBadge extends StatelessWidget {
  final String grade;
  final double fontSize;
  final double size;

  const GradeBadge(
    this.grade, {
    super.key,
    this.fontSize = 14,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final g = grade.toUpperCase();
    final color = _gradeColor(g);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        g,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _gradeColor(String g) {
    switch (g) {
      case 'A': return kSuccessGreen;
      case 'B': return kRailwayBlue;
      case 'C': return kWarningOrange;
      case 'D': return kErrorRed;
      default: return kNeutralGrey;
    }
  }
}
