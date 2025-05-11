import 'package:flutter/material.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return TextField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'monospace',
        color: colorScheme.onSecondary,
      ),
      cursorColor: colorScheme.onSecondary,
      onChanged: onInputUpdated,
      maxLength: 256,
      decoration: InputDecoration(
        labelText: inputTitle,
        labelStyle: TextStyle(
            color: colorScheme.onSecondary, fontWeight: FontWeight.w800),
        fillColor: colorScheme.secondary,
        prefixText: prefixText,
        hintText: hintText,
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: customColors.hintText,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}
