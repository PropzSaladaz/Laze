import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/core/ui/styled_long_button.dart';
import 'package:laze/presentation/home/widgets/keyboard.dart';
import 'package:laze/services/server_connector.dart';

final class _CommandControlSizes {
  static const double sideButtonWidth = 70;
  static const double sideButtonHeight = 180;
  static const double sideButtonIconSize = 48;
  static const double sideButtonLabelSize = 18;
  static const double centerPanelWidth = 195;
  static const double centerPanelHeight = sideButtonHeight;
}

class CommandBtns extends StatelessWidget {
  final int sensitivity;
  final ValueChanged<int> onSensitivityChanged;
  final ValueNotifier<String>? feedbackNotifier;

  const CommandBtns({
    super.key,
    required this.sensitivity,
    required this.onSensitivityChanged,
    this.feedbackNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 390;
        final sideWidth = math.max(
          56.0,
          math.min(_CommandControlSizes.sideButtonWidth, width * 0.18),
        );
        final centerWidth = math.max(
          148.0,
          math.min(
            _CommandControlSizes.centerPanelWidth,
            width - (sideWidth * 2) - 40,
          ),
        );
        final panelHeight =
            isCompact ? 164.0 : _CommandControlSizes.centerPanelHeight;
        final sideIconSize =
            isCompact ? 42.0 : _CommandControlSizes.sideButtonIconSize;
        final sideLabelSize =
            isCompact ? 16.0 : _CommandControlSizes.sideButtonLabelSize;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StyledLongButton(
                iconUp: Icons.keyboard_arrow_up_rounded,
                iconDown: Icons.keyboard_arrow_down_rounded,
                onPressedUp: () {
                  ServerConnector.sendInput(Input.volumeUp());
                  feedbackNotifier?.value = 'VOL ▲';
                },
                onPressedDown: () {
                  ServerConnector.sendInput(Input.volumeDown());
                  feedbackNotifier?.value = 'VOL ▼';
                },
                description: 'VOL',
                vertical: true,
                width: sideWidth,
                height: panelHeight,
                iconSize: sideIconSize,
                descriptionFontSize: sideLabelSize,
              ),
              KeyboardButton(
                width: centerWidth,
                height: panelHeight,
                feedbackNotifier: feedbackNotifier,
              ),
              StyledLongButton(
                iconUp: Icons.keyboard_arrow_up_rounded,
                iconDown: Icons.keyboard_arrow_down_rounded,
                onPressedUp: () {
                  onSensitivityChanged(sensitivity + 1);
                  feedbackNotifier?.value = 'SEN: ${sensitivity + 1}';
                },
                onPressedDown: () {
                  if (sensitivity > 1) {
                    onSensitivityChanged(sensitivity - 1);
                    feedbackNotifier?.value = 'SEN: ${sensitivity - 1}';
                  }
                },
                description: 'SEN',
                vertical: true,
                width: sideWidth,
                height: panelHeight,
                iconSize: sideIconSize,
                descriptionFontSize: sideLabelSize,
              ),
            ],
          ),
        );
      },
    );
  }
}
