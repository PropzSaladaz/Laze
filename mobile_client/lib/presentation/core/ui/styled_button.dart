import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

typedef Callback = void Function();

class StyledButton extends StatelessWidget {
  final IconData icon;
  final Callback onPressed;
  final bool isClicked;

  const StyledButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isClicked = false,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isClicked ? appColors.primary : appColors.surface_1,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: appColors.shadowLow.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(5, 2),
          ),
          BoxShadow(
            color: appColors.shadowHigh,
            spreadRadius: 4,
            blurRadius: 7,
            offset: const Offset(-5, -2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: Dimens.icon.large,
        color: isClicked ? appColors.onPrimary : appColors.text,
      ),
    );
  }
}
