import 'package:flutter/material.dart';
import 'package:mobile_client/presentation/core/themes/dimensions.dart';
import 'package:mobile_client/presentation/core/ui/styled_button.dart';
import 'package:mobile_client/presentation/new_shortcut/widgets/icon_picker.dart';

class ShortcutInputRow extends StatelessWidget {
  final void Function(String) onNameChanged;
  final void Function(IconData) onIconSelected;

  final IconData selectedIcon;

  const ShortcutInputRow({
    super.key,
    required this.onNameChanged,
    required this.onIconSelected,
    required this.selectedIcon,
  });

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
              style: const TextStyle(
                fontSize: 39,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(hintText: "Shortcut Name"),
              onChanged: onNameChanged,
            ),
            
          ),
        ),

        /// ---- TAP TO CHANGE------
        Column(
          children: [
            StyledButton(
              icon: selectedIcon, 
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
          initialIcon: selectedIcon, onIconSelected: onIconSelected),
    );
  }
}
