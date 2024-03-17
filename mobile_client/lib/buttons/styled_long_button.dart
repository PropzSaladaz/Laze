import 'package:flutter/material.dart';
import 'package:mobile_client/color_constants.dart';

class StyledLongButton extends StatelessWidget {
  final IconData iconUp;
  final IconData iconDown;
  final String description;
  final bool? vertical;
  const StyledLongButton({
    super.key,
    required this.iconUp,
    required this.iconDown,
    required this.description,
    this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: ColorConstants.background,
        borderRadius: BorderRadius.circular(25),
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
      child: _autoLayout(
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(iconUp),
            iconSize: 45,
            color: ColorConstants.mainText,
          ),
          Text(
            description,
            style: const TextStyle(color: ColorConstants.mainText),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(iconDown),
            iconSize: 45,
            color: ColorConstants.mainText,
          ),
        ],
      ),
    );
  }

  Widget _autoLayout({required List<Widget> children}) {
    if (vertical != null && vertical == true) {
      return Column(
        children: children,
      );
    } else {
      return Row(
        children: children,
      );
    }
  }
}
