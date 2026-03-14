import 'package:flutter/material.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/core/ui/split_panel_button.dart';
import 'package:laze/services/server_connector.dart';

class KeyboardButton extends StatefulWidget {
  final double width;
  final double height;

  const KeyboardButton({
    super.key,
    this.width = 176,
    this.height = 176,
  });

  @override
  State<KeyboardButton> createState() => _KeyboardButtonState();
}

class _KeyboardButtonState extends State<KeyboardButton>
    with WidgetsBindingObserver {
  String currentString = '';
  bool keyboardOn = false;
  // stores the timestamp of the last key press
  DateTime lastPressTime = DateTime.now();
  // time between each press - avoid fast consecutive key presses
  final keyPressInterval = 5; // ms
  FocusNode inputNode = FocusNode();
  FocusNode textFieldNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    inputNode.dispose();
    textFieldNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final viewInsets = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom;

    if (viewInsets == 0) {
      Future.delayed(const Duration(milliseconds: 50), () {
        final currentViewInsets = WidgetsBinding
            .instance.platformDispatcher.views.first.viewInsets.bottom;

        if (!mounted || currentViewInsets != 0) {
          return;
        }

        setState(() {
          keyboardOn = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Offstage(
          offstage: !keyboardOn,
          child: SizedBox(
            width: 1,
            height: 1,
            child: KeyboardListener(
              focusNode: inputNode,
              onKeyEvent: _onKeyPressed,
              child: TextField(
                focusNode: textFieldNode,
                onChanged: _onTextChanged,
                onSubmitted: _onSubmitted,
              ),
            ),
          ),
        ),
        SplitPanelButton(
          topText: '...',
          bottomText: 'KEYBOARD',
          onBottomPressed: _showKeyboard,
          width: widget.width,
          height: widget.height,
        ),
      ],
    );
  }

  void _showKeyboard() {
    setState(() {
      keyboardOn = true;
      textFieldNode.requestFocus();
      // inputNode.requestFocus();
    });
  }

  /// Callback to check backspace press
  /// Add timer to avoid multiple backspace for a single
  /// backspace 'click' by the user
  void _onKeyPressed(KeyEvent keyEvent) {
    // DateTime currentPressTime = DateTime.now();
    // Duration timeDifference = currentPressTime.difference(lastPressTime);
    // if (keyEvent.logicalKey == LogicalKeyboardKey.backspace &&
    //     timeDifference > Duration(milliseconds: keyPressInterval)) {

    //   ServerConnector.sendInput(Input.keyboardBackSpace());
    //   lastPressTime = currentPressTime;
    // }
  }

  /// Callback that takes care of input changes
  void _onTextChanged(String newString) {
    if (newString.length > currentString.length) {
      // send last character
      ServerConnector.sendInput(
          Input.keyboardCharacter(text: newString[newString.length - 1]));
    } else {
      ServerConnector.sendInput(Input.keyboardBackSpace());
    }

    currentString = newString;
  }

  void _onSubmitted(String value) {
    ServerConnector.sendInput(Input.keyboardEnter());
  }
}
