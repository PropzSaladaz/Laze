import 'package:flutter/material.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/buttons/styled_long_button.dart';
import 'package:mobile_client/client/dto/input.dart';

class CommandBtns extends StatelessWidget {
  final ServerConnector connector;
  const CommandBtns({super.key, required this.connector});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Volume
            StyledLongButton(
              iconUp: Icons.keyboard_arrow_up_rounded,
              iconDown: Icons.keyboard_arrow_down_rounded,
              onPressedUp: () {},
              onPressedDown: () {},
              description: "VOL",
              vertical: true,
            ),
            Column(
              children: [
                // Keyboard
                StyledLongButton(
                  iconUp: Icons.keyboard_arrow_up_rounded,
                  iconDown: Icons.keyboard_arrow_down_rounded,
                  onPressedUp: () {},
                  onPressedDown: () {},
                  description: "Keyboard",
                ),
                // Shortcut
                StyledLongButton(
                  iconUp: Icons.keyboard_arrow_up_rounded,
                  iconDown: Icons.keyboard_arrow_down_rounded,
                  onPressedUp: () {},
                  onPressedDown: () {},
                  description: "Shortcuts",
                ),
              ],
            ),
            // Speed
            StyledLongButton(
              iconUp: Icons.keyboard_arrow_up_rounded,
              iconDown: Icons.keyboard_arrow_down_rounded,
              onPressedUp: () {
                connector.sendInput(Input.changeSensitivity(
                  sensitivity: 1,
                ));
              },
              onPressedDown: () {
                connector.sendInput(Input.changeSensitivity(
                  sensitivity: -1,
                ));
              },
              description: "Speed",
              vertical: true,
            ),
          ],
        ),
      ],
    );
  }
}
