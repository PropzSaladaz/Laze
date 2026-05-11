import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

class StyledInput extends StatelessWidget {
  final Function(String)? onInputUpdated;

  final String? inputTitle;
  final String? hintText;

  final String? prefixText;

  final TextEditingController? controller;
  final bool showCounter;

  const StyledInput({
    super.key,
    this.onInputUpdated,
    this.inputTitle,
    this.hintText,
    this.prefixText,
    this.controller,
    this.showCounter = false,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return TextField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'monospace',
        color: appColors.textMuted,
        fontSize: Dimens.text.body,
      ),
      cursorColor: appColors.textMuted,
      onChanged: onInputUpdated,
      maxLength: 256,
      decoration: InputDecoration(
        labelText: inputTitle,
        labelStyle: TextStyle(
          color: appColors.text,
          fontWeight: FontWeight.w800,
        ),
        fillColor: appColors.surface_2,
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: appColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        hintText: hintText,
        border: InputBorder.none,
        counterText: showCounter ? null : '',
        hintStyle: TextStyle(
          color: appColors.textMuted,
          fontWeight: FontWeight.w300,
          fontSize: Dimens.text.body,
        ),
      ),
    );
  }
}
