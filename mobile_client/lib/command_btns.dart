import 'package:flutter/material.dart';
import 'package:mobile_client/buttons/styled_button.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/buttons/styled_long_button.dart';
import 'package:mobile_client/client/dto/input.dart';

class CommandBtns extends StatefulWidget {
  final ServerConnector connector;

  CommandBtns({super.key, required this.connector});

  @override
  State<CommandBtns> createState() => _CommandBtnsState();
}

class _CommandBtnsState extends State<CommandBtns> {
  FocusNode inputNode = FocusNode();
  bool keyBoardOn = false;

  void openKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(inputNode);
  }

  @override
  void initState() {
    super.initState();
    inputNode.addListener(() {
      print("focus");
      if (!inputNode.hasFocus) {
        print("no focus");
        keyBoardOn = false;
      }
    });
  }

  @override
  void dispose() {
    inputNode.dispose();
    super.dispose();
  }

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
                Container(
                  width: 100,
                  child: Visibility(
                    visible: keyBoardOn,
                    child: TextField(
                      focusNode: inputNode,
                      autofocus: true,
                    ),
                  ),
                ),
                // Keyboard
                StyledLongButton(
                  iconUp: Icons.keyboard_arrow_up_rounded,
                  iconDown: Icons.keyboard_arrow_down_rounded,
                  description: "Keyboard",
                  onPressedDown: () {
                    setState(() {
                      keyBoardOn = true;
                    });
                    inputNode.requestFocus();
                  },
                ),
                // Shortcut
                StyledLongButton(
                    iconUp: Icons.keyboard_arrow_up_rounded,
                    iconDown: Icons.keyboard_arrow_down_rounded,
                    description: "Shortcuts",
                    onPressedDown: () {}),
              ],
            ),
            // Speed
            StyledLongButton(
              iconUp: Icons.keyboard_arrow_up_rounded,
              iconDown: Icons.keyboard_arrow_down_rounded,
              onPressedUp: () {
                widget.connector.sendInput(Input.changeSensitivity(
                  sensitivity: 1,
                ));
              },
              onPressedDown: () {
                widget.connector.sendInput(Input.changeSensitivity(
                  sensitivity: -1,
                ));
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
