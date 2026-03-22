import 'package:flutter/material.dart';
import 'package:laze/domain/models/shortcut/shortcut.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/services/server_connector.dart';

class ShortcutIcon extends StatelessWidget {
  final Shortcut shortcut;
  final ValueNotifier<String>? feedbackNotifier;
  final bool showShadow;

  const ShortcutIcon({
    super.key,
    required this.shortcut,
    this.feedbackNotifier,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        StyledButton(
          icon: shortcut.icon,
          showShadow: showShadow,
          onPressed: () {
            ServerConnector.sendInput(Input.runCommand(shortcut.commands));
            feedbackNotifier?.value = shortcut.name;
          },
        ),
        Text(
          shortcut.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: appColors.textMuted),
        ),
      ],
    );
  }
}
