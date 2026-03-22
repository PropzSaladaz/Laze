import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

abstract final class AppShadows {
  static List<BoxShadow> raisedControl(AppColors appColors) {
    final isLight = appColors.bg.computeLuminance() > 0.5;

    if (isLight) {
      return [
        const BoxShadow(
          color: Color.fromRGBO(255, 255, 255, 0.84),
          offset: Offset(-2, -1),
          blurRadius: 5,
        ),
        const BoxShadow(
          color: Color.fromRGBO(255, 255, 255, 0.77),
          offset: Offset(-8, -3),
          blurRadius: 9,
        ),
        BoxShadow(
          color: appColors.shadowLow.withValues(alpha: 0.09),
          offset: const Offset(6, 1),
          blurRadius: 6,
        ),
      ];
    }

    // Dark / black themes: subtle surface highlight + drop shadow only.
    return [
      BoxShadow(
        color: appColors.surface_3.withValues(alpha: 0.8),
        offset: const Offset(-2, -1),
        blurRadius: 5,
      ),
      BoxShadow(
        color: appColors.surface_3.withValues(alpha: 0.5),
        offset: const Offset(-8, -3),
        blurRadius: 9,
      ),
      BoxShadow(
        color: appColors.shadowLow.withValues(alpha: 0.35),
        offset: const Offset(6, 1),
        blurRadius: 6,
      ),
    ];
  }

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
