import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/colors.dart';

typedef Callback = void Function();

class StyledLongButton extends StatelessWidget {
  final IconData iconUp;
  final IconData iconDown;
  final Callback? onPressedUp;
  final Callback onPressedDown;
  final String description;
  final bool? vertical;
  const StyledLongButton({
    super.key,
    required this.iconUp,
    required this.iconDown,
    required this.description,
    required this.onPressedDown,
    this.onPressedUp,
    this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();

    return Container(
      margin: const EdgeInsets.all(10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: customColors!.shadowColorDark.withOpacity(0.2), // Shadow color
            spreadRadius: 1, // Spread radius
            blurRadius: 7, // Blur radius
            offset: const Offset(5, 2), // Offset (horizontal, vertical)
          ),
          BoxShadow(
            color: customColors.shadowColorBright.withOpacity(1), // Shadow color
            spreadRadius: 2, // Spread radius
            blurRadius: 7, // Blur radius
            offset: const Offset(-5, -2), // Offset (horizontal, vertical)
          ),
        ],
      ),
      child: _autoLayout(context),
    );
  }

  Widget _autoSpacing({required double spacing}) {
    if (vertical != null && vertical == true) {
      return SizedBox(
        height: spacing,
      );
    }
    return SizedBox(
      width: spacing / 3,
    );
  }

  Widget _autoLayout(BuildContext context) {
    if (vertical != null && vertical == true) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: onPressedUp,
            icon: Icon(iconUp),
            iconSize: 45,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          _autoSpacing(spacing: 12),
          Text(
            description,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          _autoSpacing(spacing: 12),
          IconButton(
            onPressed: onPressedDown,
            icon: Icon(iconDown),
            iconSize: 45,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      );
    }
    return Row(
      children: [
        TextButton(
          style: const ButtonStyle(
            overlayColor: MaterialStatePropertyAll(Colors.white),
          ),
          onPressed: onPressedDown,
          child: Container(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
            child: Text(
              description,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}
