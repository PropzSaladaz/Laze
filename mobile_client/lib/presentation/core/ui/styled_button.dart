import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/press_animation_mixin.dart';

class StyledButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClicked;
  final double? width;
  final double? height;
  final double? iconSize;
  final EdgeInsetsGeometry margin;
  final bool showShadow;

  const StyledButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isClicked = false,
    this.width,
    this.height,
    this.iconSize,
    this.margin = const EdgeInsets.all(8),
    this.showShadow = true,
  });

  @override
  State<StyledButton> createState() => _StyledButtonState();
}

class _StyledButtonState extends State<StyledButton>
    with PressAnimationMixin<StyledButton> {
  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final flat = isPressed || widget.isClicked || !widget.showShadow;

    return Listener(
      onPointerDown: (_) => handlePointerDown(),
      onPointerUp: (_) => handlePointerUp(),
      onPointerCancel: (_) => handlePointerCancel(),
      child: AnimatedContainer(
        duration: isPressed ? pressDownDuration : pressUpDuration,
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: flat ? null : AppShadows.raisedControl(appColors),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isClicked ? appColors.primary : appColors.bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: appColors.border,
              width: Dimens.button.styledButtonBorderWidth,
            ),
          ),
          child: IconButton(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon),
            padding: EdgeInsets.zero,
            iconSize: widget.iconSize ?? Dimens.icon.medium,
            color: widget.isClicked ? appColors.textInverse : appColors.textMuted,
          ),
        ),
      ),
    );
  }
}
