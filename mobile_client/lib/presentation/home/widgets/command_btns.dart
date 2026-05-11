import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/ui/styled_long_button.dart';
import 'package:laze/presentation/home/widgets/keyboard.dart';
import 'package:laze/services/server_connector.dart';

final class _CommandControlSizes {
  static const double sideButtonWidth = 70;
  static const double sideButtonHeight = 172;
  static const double sideButtonIconSize = 44;
  static final double sideButtonLabelSize = Dimens.text.title;
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
        // Subtract the 8px consumed by Padding(horizontal: 4) so that child
        // widths add up to the Row's actual available space.
        final effectiveWidth = width - 8;
        final isCompact = width < 390;
        final sideWidth = math.max(
          56.0,
          math.min(_CommandControlSizes.sideButtonWidth, effectiveWidth * 0.18),
        );
        final centerWidth = math.max(
          148.0,
          math.min(
            _CommandControlSizes.centerPanelWidth,
            effectiveWidth - (sideWidth * 2) - 40,
          ),
        );
        final panelHeight =
            isCompact ? 156.0 : _CommandControlSizes.centerPanelHeight;
        final sideIconSize =
            isCompact ? 38.0 : _CommandControlSizes.sideButtonIconSize;
        final sideLabelSize =
            isCompact ? Dimens.text.body : _CommandControlSizes.sideButtonLabelSize;

        final spacing = Dimens.spacing.sm;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              SizedBox(width: spacing),
              KeyboardButton(
                width: centerWidth,
                height: panelHeight,
                feedbackNotifier: feedbackNotifier,
              ),
              SizedBox(width: spacing),
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
