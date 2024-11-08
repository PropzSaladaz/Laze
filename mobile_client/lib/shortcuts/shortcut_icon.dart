import 'package:flutter/material.dart';
import 'package:mobile_client/buttons/styled_button.dart';
import 'package:mobile_client/client/dto/input.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/shortcuts/shortcut.dart';

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