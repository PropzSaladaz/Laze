import 'package:flutter/material.dart';
import 'package:mobile_client/core/constants/color_constants.dart';

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
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorConstants.background,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2), // Shadow color
            spreadRadius: 2, // Spread radius
            blurRadius: 7, // Blur radius
            offset: const Offset(5, 2), // Offset (horizontal, vertical)
          ),
          BoxShadow(
            color: Colors.white.withOpacity(1), // Shadow color
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
        color: ColorConstants.mainText,
      ),
    );
  }
}
