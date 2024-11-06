import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_client/buttons/styled_button.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/buttons/styled_long_button.dart';
import 'package:mobile_client/client/dto/input.dart';
import 'package:mobile_client/keyboard.dart';
import 'package:mobile_client/shortcuts/shortcuts_sheet.dart';

class CommandBtns extends StatefulWidget {
  final void Function() onShowShortcutsSheet;

  const CommandBtns({
    super.key, 
    required this.onShowShortcutsSheet,
  });

  @override
  State<CommandBtns> createState() => _CommandBtnsState();
}

class _CommandBtnsState extends State<CommandBtns> {
  bool isShortcutsSheetVisible = false;

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
    // occupy the rest of the screen - use Expanded
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // VOLUME
              StyledLongButton(
                iconUp: Icons.keyboard_arrow_up_rounded,
                iconDown: Icons.keyboard_arrow_down_rounded,
                onPressedUp: () {
                  ServerConnector.sendInput(Input.volumeUp());
                },
                onPressedDown: () {
                  ServerConnector.sendInput(Input.volumeDown());
                },
                description: "VOL",
                vertical: true,
              ),
              Column(
                children: [
                  // KEYBOARD
                  const KeyboardButton(),
                  // SHORTCUTS
                  StyledLongButton(
                    iconUp: Icons.keyboard_arrow_up_rounded,
                    iconDown: Icons.keyboard_arrow_down_rounded,
                    description: "Shortcuts",
                    onPressedDown: widget.onShowShortcutsSheet
                  ),
                ],
              ),
              // SENSITIVITY
              StyledLongButton(
                iconUp: Icons.keyboard_arrow_up_rounded,
                iconDown: Icons.keyboard_arrow_down_rounded,
                onPressedUp: () {
                  ServerConnector.sendInput(Input.sensitivityUp());
                },
                onPressedDown: () {
                  ServerConnector.sendInput(Input.sensitivityDown());
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
                  ServerConnector.sendInput(Input.mute());
                },
              ),
              // BRIGHTNESS
              StyledButton(
                icon: Icons.brightness_high_sharp,
                onPressed: () {
                  ServerConnector.sendInput(Input.brightnessDown());
                },
              ),
              //PAUSE
              StyledButton(
                icon: Icons.pause,
                onPressed: () {
                  ServerConnector.sendInput(Input.pause());
                },
              ),
              // PLAY
              StyledButton(
                icon: Icons.play_arrow,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
