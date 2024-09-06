import 'package:flutter/material.dart';
import 'package:mobile_client/buttons/styled_long_button.dart';
import 'package:mobile_client/client/dto/input.dart';
import 'package:mobile_client/client/server_connector.dart';

class KeyboardButton extends StatefulWidget {
  final ServerConnector connector;

  const KeyboardButton({
    super.key,
    required this.connector,
  });

  @override
  State<KeyboardButton> createState() => _KeyboardButtonState();
}

class _KeyboardButtonState extends State<KeyboardButton>
    with WidgetsBindingObserver {

  String currentString = "";
  bool keyboardOn = false;
  FocusNode inputNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    inputNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (MediaQuery.of(context).viewInsets.bottom == 0) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (MediaQuery.of(context).viewInsets.bottom == 0) {
          setState(() {
            keyboardOn = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          child: Visibility(
              visible: keyboardOn,
              child: TextField(
                focusNode: inputNode,
                autofocus: true,
                onChanged: _handleKeyboardButtonInput,
              )),
        ),
        StyledLongButton(
          iconUp: Icons.keyboard_arrow_up_rounded,
          iconDown: Icons.keyboard_arrow_down_rounded,
          description: "Keyboard",
          onPressedDown: () {
            setState(() {
              keyboardOn = true;
            });
            inputNode.requestFocus();
          },
        ),
      ],
    );
  }

  void _handleKeyboardButtonInput(String newString) {
    // 1 character was deleted
    if (newString.length < currentString.length) {
      widget.connector.sendInput(Input.keyboardBackSpace());
    }
    else { // send last character
      widget.connector.sendInput(Input.keyboardCharacter(charCode: newString.codeUnitAt(-1)));
    }
    
    currentString = newString;
  }
}
