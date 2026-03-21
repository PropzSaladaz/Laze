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
            width: _CommandControlSizes.sideButtonWidth,
            height: _CommandControlSizes.sideButtonHeight,
            iconSize: _CommandControlSizes.sideButtonIconSize,
            descriptionFontSize: _CommandControlSizes.sideButtonLabelSize,
          ),
          KeyboardButton(
            width: _CommandControlSizes.centerPanelWidth,
            height: _CommandControlSizes.centerPanelHeight,
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
            width: _CommandControlSizes.sideButtonWidth,
            height: _CommandControlSizes.sideButtonHeight,
            iconSize: _CommandControlSizes.sideButtonIconSize,
            descriptionFontSize: _CommandControlSizes.sideButtonLabelSize,
          ),
        ],
      ),
    );
  }
}
