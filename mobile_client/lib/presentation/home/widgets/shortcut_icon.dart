import 'package:flutter/material.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';
import 'package:mobile_client/presentation/core/ui/styled_button.dart';
import 'package:mobile_client/data/services/input.dart';
import 'package:mobile_client/services/server_connector.dart';

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