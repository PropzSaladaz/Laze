import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

class CtaButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double widthFactor;
  final double fontSize;

  const CtaButton({
    super.key,
    this.text,
    this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.widthFactor = 0.75,
    this.fontSize = 38,
  }) : assert(
          (text != null) != (icon != null),
          'Provide either text or icon, not both',
        );

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final resolvedBackground = backgroundColor ?? appColors.primary;
    final resolvedForeground = foregroundColor ?? appColors.surface_1;
    final resolvedBorder = borderColor ?? appColors.surface_1;

    final decoration = BoxDecoration(
      color: resolvedBackground,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: resolvedBorder, width: 1),
      boxShadow: AppShadows.raisedControl,
    );

    if (icon != null) {
      return Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            decoration: decoration,
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 26),
                shape: const StadiumBorder(),
              ),
              child: Icon(icon, color: resolvedForeground, size: 32),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          decoration: decoration,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: const StadiumBorder(),
            ),
            child: Text(
              text!,
              style: TextStyle(
                color: resolvedForeground,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                fontFamily: 'NunitoSans',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
