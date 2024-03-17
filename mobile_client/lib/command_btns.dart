import 'package:flutter/material.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/buttons/styled_long_button.dart';

class CommandBtns extends StatelessWidget {
  final ServerConnector connector;
  const CommandBtns({super.key, required this.connector});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StyledLongButton(
              iconUp: Icons.keyboard_arrow_up_rounded,
              iconDown: Icons.keyboard_arrow_down_rounded,
              description: "VOL",
              vertical: true,
            ),
            Column(
              children: [
                StyledLongButton(
                  iconUp: Icons.keyboard_arrow_up_rounded,
                  iconDown: Icons.keyboard_arrow_down_rounded,
                  description: "Keyboard",
                ),
                StyledLongButton(
                  iconUp: Icons.keyboard_arrow_up_rounded,
                  iconDown: Icons.keyboard_arrow_down_rounded,
                  description: "Shortcuts",
                ),
              ],
            ),
            StyledLongButton(
              iconUp: Icons.keyboard_arrow_up_rounded,
              iconDown: Icons.keyboard_arrow_down_rounded,
              description: "Speed",
              vertical: true,
            ),
          ],
        ),
      ],
    );
  }
}
