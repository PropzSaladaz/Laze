import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/services/server_connector.dart';
import 'package:laze/presentation/core/ui/styled_long_button.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/home/widgets/keyboard.dart';

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
          _fourButtonRow([
            _ButtonData(Icons.volume_off, Input.mute()),
            _ButtonData(Icons.power_settings_new, Input.shutdown()),
            _ButtonData(Icons.pause, Input.pause()),
            _ButtonData(Icons.play_arrow, Input.play()),
          ]),
          _fourButtonRow([
            _ButtonData(Icons.fullscreen, Input.fullScreen()),
            _ButtonData(Icons.close, Input.closeTab()),
            _ButtonData(Icons.arrow_left, Input.previousTab()),
            _ButtonData(Icons.arrow_right, Input.nextTab()),
          ]),
        ],
      ),
    );
  }

  Widget _fourButtonRow(List<_ButtonData> buttons) {
    assert(buttons.length == 4, "There must be exactly 4 buttons");

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // MUTE
        StyledButton(
          icon: buttons[0].icon,
          onPressed: () {
            ServerConnector.sendInput(buttons[0].dataToSend);
          },
        ),
        // BRIGHTNESS
        StyledButton(
          icon: buttons[1].icon,
          onPressed: () {
            ServerConnector.sendInput(buttons[1].dataToSend);
          },
        ),
        //PAUSE
        StyledButton(
          icon: buttons[2].icon,
          onPressed: () {
            ServerConnector.sendInput(buttons[2].dataToSend);
          },
        ),
        // PLAY
        StyledButton(
          icon: buttons[3].icon,
          onPressed: () {
            ServerConnector.sendInput(buttons[3].dataToSend);
          },
        ),
      ],
    );
  }
}

class _ButtonData {
  final IconData icon;
  Uint8List dataToSend;

  _ButtonData(this.icon, this.dataToSend);
}
