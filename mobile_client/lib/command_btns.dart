import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_client/buttons/styled_button.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/buttons/styled_long_button.dart';
import 'package:mobile_client/client/dto/input.dart';
import 'package:mobile_client/keyboard.dart';

class CommandBtns extends StatefulWidget {
  final ServerConnector connector;

  const CommandBtns({
    super.key, 
    required this.connector
  });

  @override
  State<CommandBtns> createState() => _CommandBtnsState();
}

class _CommandBtnsState extends State<CommandBtns> {
  String _pressedKey = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // VOLUME
            StyledLongButton(
              iconUp: Icons.keyboard_arrow_up_rounded,
              iconDown: Icons.keyboard_arrow_down_rounded,
              onPressedUp: () {
                widget.connector.sendInput(Input.volumeUp());
              },
              onPressedDown: () {
                widget.connector.sendInput(Input.volumeDown());
              },
              description: "VOL",
              vertical: true,
            ),
            Column(
              children: [
                // KEYBOARD
                KeyboardButton(connector: widget.connector),
                // SHORTCUTS
                StyledLongButton(
                    iconUp: Icons.keyboard_arrow_up_rounded,
                    iconDown: Icons.keyboard_arrow_down_rounded,
                    description: "Shortcuts",
                    onPressedDown: () {}),
              ],
            ),
            // SENSITIVITY
            StyledLongButton(
              iconUp: Icons.keyboard_arrow_up_rounded,
              iconDown: Icons.keyboard_arrow_down_rounded,
              onPressedUp: () {
                widget.connector.sendInput(Input.sensitivityUp());
              },
              onPressedDown: () {
                widget.connector.sendInput(Input.sensitivityDown());
              },
              description: "Speed",
              vertical: true,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // MUTE
            StyledButton(
              icon: Icons.volume_off,
              onPressed: () {
                widget.connector.sendInput(Input.mute());
              },
            ),
            // BRIGHTNESS
            StyledButton(
              icon: Icons.brightness_high_sharp,
              onPressed: () {
                widget.connector.sendInput(Input.brightnessDown());
              },
            ),
            //PAUSE
            StyledButton(
              icon: Icons.pause,
              onPressed: () {
                widget.connector.sendInput(Input.pause());
              },
            ),
            // PLAY
            StyledButton(
              icon: Icons.play_arrow,
              onPressed: () {},
            ),
          ],
        )
      ],
    );
  }
}
