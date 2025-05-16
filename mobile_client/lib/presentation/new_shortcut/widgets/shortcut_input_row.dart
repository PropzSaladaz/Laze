import 'package:flutter/material.dart';
import 'package:mobile_client/presentation/core/ui/styled_button.dart';
import 'package:mobile_client/presentation/new_shortcut/widgets/icon_picker.dart';

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

  late String shortcutName = widget.initShortcutName ?? "";

  @override
  void initState() {
    _controller = TextEditingController(text: shortcutName);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: FractionallySizedBox(
            alignment: Alignment.center,
            widthFactor: 0.7,
            child: TextField(
              controller: _controller,
              cursorColor: Theme.of(context).colorScheme.onSecondary,
              style: const TextStyle(
                fontSize: 39,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: "Shortcut Name",
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 32,
                ),
              ),
              onChanged: widget.onNameChanged,
            ),
          ),
        ),

        /// ---- TAP TO CHANGE------
        Column(
          children: [
            StyledButton(
              icon: widget.initIcon,
              onPressed: () => _openIconPicker(context),
            ),
            Text(
              "Tap to change",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        )
      ],
    );
  }

  void _openIconPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => IconPicker(
        initialIcon: widget.initIcon, 
        onIconSelected: widget.onIconSelected
      ),
    );
  }
}
