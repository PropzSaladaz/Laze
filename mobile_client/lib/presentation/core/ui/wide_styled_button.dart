import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

typedef Callback = void Function();

class WideStyledButton extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String? text;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? backgroundColor;

  final Callback onPressed;



  const WideStyledButton({
    super.key,
    this.icon,
    this.iconColor,
    this.text,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.backgroundColor,
    required this.onPressed,
  }) : assert(
    (icon == null && text != null) ||
    (icon != null && text == null),
    "Either Icon is set, or text + tetColor is set, but not both"
  );

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: appColors.shadowLow.withValues(alpha: 0.2),
            spreadRadius: 3,
            blurRadius: 6,
            offset: const Offset(3, 2),
          ),
          BoxShadow(
            color: appColors.shadowHigh,
            spreadRadius: 4,
            blurRadius: 7,
            offset: const Offset(-5, -2),
          ),
        ],
      ),
      child: icon != null ? 
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 60,
          color: iconColor,
        )
        :
        TextButton(
          onPressed: onPressed, 
          child: Text(
            text!,  // assert non-null - if icon is null then we must have text
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          )
        ),
    );
  }
}
