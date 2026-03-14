import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

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
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Container(
      margin: const EdgeInsets.all(10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: appColors.surface_1,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: appColors.shadowLow.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(5, 2),
          ),
          BoxShadow(
            color: appColors.shadowHigh,
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(-5, -2),
          ),
        ],
      ),
      child: _autoLayout(context, appColors),
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

  Widget _autoLayout(BuildContext context, AppColors appColors) {
    if (vertical != null && vertical == true) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: onPressedUp,
            icon: Icon(iconUp),
            iconSize: 45,
            color: appColors.text,
          ),
          _autoSpacing(spacing: 12),
          Text(
            description,
            style: TextStyle(color: appColors.text),
          ),
          _autoSpacing(spacing: 12),
          IconButton(
            onPressed: onPressedDown,
            icon: Icon(iconDown),
            iconSize: 45,
            color: appColors.text,
          ),
        ],
      );
    }
    return Row(
      children: [
        TextButton(
          style: ButtonStyle(
            overlayColor: WidgetStatePropertyAll(appColors.hover),
          ),
          onPressed: onPressedDown,
          child: Container(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
            child: Text(
              description,
              style: TextStyle(color: appColors.text, fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}
