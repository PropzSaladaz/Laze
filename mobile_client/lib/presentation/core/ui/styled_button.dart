import 'package:flutter/material.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';

typedef Callback = void Function();

class StyledButton extends StatelessWidget {
  final IconData icon;
  final Callback onPressed;

  const StyledButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        // color: ColorConstants.background,
        boxShadow: [
          BoxShadow(
            color: customColors!.shadowColorDark.withOpacity(0.2), // Shadow color
            spreadRadius: 2, // Spread radius
            blurRadius: 7, // Blur radius
            offset: const Offset(5, 2), // Offset (horizontal, vertical)
          ),
          BoxShadow(
            color: customColors.shadowColorBright.withOpacity(1), // Shadow color
            spreadRadius: 4, // Spread radius
            blurRadius: 7, // Blur radius
            offset: const Offset(-5, -2), // Offset (horizontal, vertical)
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 45,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
