import 'package:flutter/material.dart';
import 'package:mobile_client/color_constants.dart';

class StyledButton extends StatelessWidget {
  final IconData icon;
  const StyledButton({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        onPressed: () {},
        icon: Icon(icon),
        iconSize: 45,
        color: ColorConstants.mainText,
      ),
    );
  }
}
