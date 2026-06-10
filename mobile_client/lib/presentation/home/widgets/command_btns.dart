import 'package:flutter/material.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/ui/styled_long_button.dart';
import 'package:laze/presentation/home/widgets/keyboard.dart';
import 'package:laze/services/server_connector.dart';

final class _CommandControlSizes {
  static const double sideButtonWidth = 70;
  static const double sideButtonHeight = 172;
  static const double sideButtonIconSize = 32; // Reduced for better balance
  static final double sideButtonLabelSize = Dimens.text.title;
  static const double centerPanelWidth = 160; // Reduced from 195 to be more "square"
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
        final isCompact = constraints.maxWidth < 390;
        final horizontalPadding = isCompact ? Dimens.spacing.md : Dimens.spacing.xl;
        final available = constraints.maxWidth - 2 * horizontalPadding;
        final sideWidth = (available * 0.2)
            .clamp(52.0, _CommandControlSizes.sideButtonWidth);
        final centerWidth = (available - 2 * sideWidth)
            .clamp(100.0, _CommandControlSizes.centerPanelWidth);
        final panelHeight = isCompact ? 156.0 : _CommandControlSizes.centerPanelHeight;
        final sideIconSize = isCompact ? 28.0 : _CommandControlSizes.sideButtonIconSize;
        final sideLabelSize = isCompact ? Dimens.text.body : _CommandControlSizes.sideButtonLabelSize;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                margin: EdgeInsets.zero,
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
                  feedbackNotifier?.value = 'Sensitivity: ${sensitivity + 1}';
                },
                onPressedDown: () {
                  if (sensitivity > 1) {
                    onSensitivityChanged(sensitivity - 1);
                    feedbackNotifier?.value = 'Sensitivity: ${sensitivity - 1}';
                  }
                },
                description: 'SEN',
                vertical: true,
                width: sideWidth,
                height: panelHeight,
                margin: EdgeInsets.zero,
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
