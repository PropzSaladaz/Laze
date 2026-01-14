import 'package:flutter/material.dart';
import 'package:laze/domain/models/shortcut/shortcut.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/services/server_connector.dart';

class ShortcutIcon extends StatelessWidget {
  final Shortcut shortcut;

  const ShortcutIcon({
    super.key,
    required this.shortcut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StyledButton(
          icon: shortcut.icon,
          onPressed: () {
            ServerConnector.sendInput(
              Input.runCommand(shortcut.commands)
            );
          },
        ),
        Text(shortcut.name),
      ],
    );
  }
}