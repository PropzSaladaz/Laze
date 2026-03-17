import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

abstract final class AppShadows {
  static const List<BoxShadow> raisedControl = [
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.84),
      offset: Offset(-2, -1),
      blurRadius: 5,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.77),
      offset: Offset(-8, -3),
      blurRadius: 9,
    ),
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.68),
      offset: Offset(-18, -8),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color.fromRGBO(95, 95, 95, 0.09),
      offset: Offset(6, 1),
      blurRadius: 6,
    ),
    BoxShadow(
      color: Color.fromRGBO(95, 95, 95, 0.1),
      offset: Offset(1, 0),
      blurRadius: 3,
    ),
  ];

  static List<BoxShadow> raisedPanel(AppColors appColors) => [
        BoxShadow(
          color: appColors.shadowLow.withValues(alpha: 0.18),
          spreadRadius: 2,
          blurRadius: 7,
          offset: const Offset(4, 3),
        ),
        BoxShadow(
          color: appColors.shadowHigh,
          spreadRadius: 3,
          blurRadius: 8,
          offset: const Offset(-5, -2),
        ),
      ];

  static List<BoxShadow> surfaceCard(AppColors appColors) => [
        BoxShadow(
          color: appColors.shadowLow.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: appColors.shadowHigh.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}
