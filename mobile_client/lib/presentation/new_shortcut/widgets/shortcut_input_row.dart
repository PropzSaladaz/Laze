import 'package:flutter/material.dart';
import 'package:laze/domain/models/shortcut/shortcut.dart';
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

  int get _nameLength => _controller.text.characters.length;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initShortcutName ?? '');
    _controller.addListener(_handleTextChanged);
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
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    const buttonHeight = 64.0;
    final counterColor = _nameLength >= Shortcut.maxNameLength
        ? appColors.primary
        : appColors.textMuted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;
        final buttonWidth = isCompact ? 88.0 : 116.0;
        final inputFontSize = isCompact ? 24.0 : 30.0;
        final hintFontSize = isCompact ? 21.0 : 26.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                      maxLength: Shortcut.maxNameLength,
                      style: TextStyle(
                        color: appColors.textMuted,
                        fontSize: inputFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Shortcut Name...',
                        hintStyle: TextStyle(
                          color: appColors.textMuted,
                          fontWeight: FontWeight.w300,
                          fontSize: hintFontSize,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 18 : 24,
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
                    iconSize: isCompact ? 26 : 30,
                    icon: widget.initIcon,
                    onPressed: () => _openIconPicker(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_nameLength/${Shortcut.maxNameLength}',
                  style: TextStyle(
                    color: counterColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
