import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/presentation/new_shortcut/widgets/icon_picker.dart';

class ShortcutInputRow extends StatefulWidget {
  final void Function(String) onNameChanged;
  final void Function(IconData) onIconSelected;

  final IconData initIcon;

  final String? initShortcutName;

  const ShortcutInputRow({
    super.key,
    required this.onNameChanged,
    required this.onIconSelected,
    required this.initIcon,
    this.initShortcutName,
  });

  @override
  State<ShortcutInputRow> createState() => _ShortcutInputRowState();
}

class _ShortcutInputRowState extends State<ShortcutInputRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initShortcutName ?? '');
  }

  @override
  void didUpdateWidget(covariant ShortcutInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextName = widget.initShortcutName ?? '';
    if (nextName != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: nextName,
        selection: TextSelection.collapsed(offset: nextName.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    const buttonHeight = 64.0;
    const buttonWidth = 116.0;

    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        color: appColors.border,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: appColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              cursorColor: appColors.text,
              maxLength: 64,
              style: TextStyle(
                color: appColors.textMuted,
                fontSize: 30,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Shortcut Name...',
                hintStyle: TextStyle(
                  color: appColors.textMuted,
                  fontWeight: FontWeight.w300,
                  fontSize: 26,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onChanged: widget.onNameChanged,
            ),
          ),
          StyledButton(
            width: buttonWidth,
            height: buttonHeight,
            margin: EdgeInsets.zero,
            iconSize: 30,
            icon: widget.initIcon,
            onPressed: () => _openIconPicker(context),
          ),
        ],
      ),
    );
  }

  void _openIconPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => IconPicker(
          initialIcon: widget.initIcon, onIconSelected: widget.onIconSelected),
    );
  }
}
