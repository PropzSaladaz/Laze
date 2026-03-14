import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

class StyledInput extends StatelessWidget {
  final Function(String)? onInputUpdated;

  final String? inputTitle;
  final String? hintText;

  final String? prefixText;

  final TextEditingController? controller;

  const StyledInput({
    super.key,
    this.onInputUpdated,
    this.inputTitle,
    this.hintText,
    this.prefixText,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return TextField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'monospace',
        color: appColors.text,
      ),
      cursorColor: appColors.text,
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
        hintText: hintText,
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: appColors.textMuted,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}
