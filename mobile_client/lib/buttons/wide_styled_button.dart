import 'package:flutter/material.dart';
import 'package:mobile_client/color_constants.dart';

typedef Callback = void Function();

class WideStyledButton extends StatelessWidget {
  final IconData icon;
  final Callback onPressed;
  final Color backgroundColor;
  final Color iconColor;

  const WideStyledButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2), // Shadow color
            spreadRadius: 3, // Spread radius
            blurRadius: 6, // Blur radius
            offset: const Offset(3, 2), // Offset (horizontal, vertical)
          ),
          // BoxShadow(
          //   color: Colors.white.withOpacity(1), // Shadow color
          //   spreadRadius: 4, // Spread radius
          //   blurRadius: 7, // Blur radius
          //   offset: const Offset(-5, -2), // Offset (horizontal, vertical)
          // ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 60,
        color: iconColor,
      ),
    );
  }
}
