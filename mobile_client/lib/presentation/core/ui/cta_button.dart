import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/press_animation_mixin.dart';

class CtaButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double widthFactor;
  final double fontSize;
  final double borderWidth;
  final bool showShadow;

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
    this.borderWidth = 1,
    this.showShadow = true,
  }) : assert(
          (text != null) != (icon != null),
          'Provide either text or icon, not both',
        );

  @override
  State<CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<CtaButton>
    with PressAnimationMixin<CtaButton> {
  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final resolvedBackground = widget.backgroundColor ?? appColors.primary;
    final resolvedForeground = widget.foregroundColor ?? appColors.surface_1;
    final resolvedBorder = widget.borderColor ?? appColors.surface_1;

    final decoration = BoxDecoration(
      color: resolvedBackground,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: resolvedBorder, width: widget.borderWidth),
      boxShadow: isPressed || !widget.showShadow
          ? null
          : AppShadows.raisedControl(appColors),
    );

    Widget content;
    if (widget.icon != null) {
      content = TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 26),
          shape: const StadiumBorder(),
          overlayColor: Colors.transparent,
        ),
        child: Icon(widget.icon, color: resolvedForeground, size: 32),
      );
    } else {
      content = TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: const StadiumBorder(),
          overlayColor: Colors.transparent,
        ),
        child: Text(
          widget.text!,
          style: TextStyle(
            color: resolvedForeground,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w900,
            fontFamily: 'NunitoSans',
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: widget.widthFactor,
        child: Listener(
          onPointerDown: (_) => handlePointerDown(),
          onPointerUp: (_) => handlePointerUp(),
          onPointerCancel: (_) => handlePointerCancel(),
          child: AnimatedScale(
            scale: isPressed ? 0.96 : 1.0,
            duration: isPressed ? pressDownDuration : pressUpDuration,
            curve: isPressed ? Curves.easeIn : Curves.elasticOut,
            child: AnimatedContainer(
              duration: isPressed ? pressDownDuration : pressUpDuration,
              decoration: decoration,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
