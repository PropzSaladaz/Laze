import 'dart:async';

import 'package:flutter/material.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/core/ui/split_panel_button.dart';
import 'package:laze/services/server_connector.dart';

class KeyboardButton extends StatefulWidget {
  final double width;
  final double height;
  final ValueNotifier<String>? feedbackNotifier;

  const KeyboardButton({
    super.key,
    this.width = 176,
    this.height = 176,
    this.feedbackNotifier,
  });

  @override
  State<KeyboardButton> createState() => _KeyboardButtonState();
}

class _KeyboardButtonState extends State<KeyboardButton>
    with WidgetsBindingObserver {
  // The TextField is always kept at this length so there are always characters
  // to delete. After each onChanged the controller is reset back to the pad,
  // making hold-backspace work indefinitely regardless of display state.
  static const String _pad = 'aaaaaaaaaaaaaaaaaaaaaaaaa'; // 25 chars

  late final TextEditingController _textController;
  final FocusNode _inputNode = FocusNode();
  final FocusNode _textFieldNode = FocusNode();

  bool _keyboardOn = false;
  String _typedText = ''; // display-only tracking

  String _displayText = '...';
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _pad);
    WidgetsBinding.instance.addObserver(this);
    widget.feedbackNotifier?.addListener(_onExternalFeedback);
  }

  @override
  void didUpdateWidget(KeyboardButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedbackNotifier != widget.feedbackNotifier) {
      oldWidget.feedbackNotifier?.removeListener(_onExternalFeedback);
      widget.feedbackNotifier?.addListener(_onExternalFeedback);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.feedbackNotifier?.removeListener(_onExternalFeedback);
    _clearTimer?.cancel();
    _textController.dispose();
    _inputNode.dispose();
    _textFieldNode.dispose();
    super.dispose();
  }

  void _onExternalFeedback() {
    if (!_keyboardOn && mounted) {
      setState(() => _displayText = widget.feedbackNotifier!.value);
      _scheduleClear();
    }
  }

  void _scheduleClear() {
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _displayText = '...');
    });
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

        if (!mounted || currentViewInsets != 0) return;

        _textFieldNode.unfocus();
        setState(() {
          _keyboardOn = false;
          _typedText = '';
          _displayText = '...';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Offstage(
          offstage: !_keyboardOn,
          child: SizedBox(
            width: 1,
            height: 1,
            child: KeyboardListener(
              focusNode: _inputNode,
              onKeyEvent: (_) {},
              child: TextField(
                controller: _textController,
                focusNode: _textFieldNode,
                onChanged: _onTextChanged,
                onSubmitted: _onSubmitted,
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          ),
        ),
        SplitPanelButton(
          topText: _displayText,
          bottomText: 'KEYBOARD',
          onBottomPressed: _showKeyboard,
          width: widget.width,
          height: widget.height,
        ),
      ],
    );
  }

  void _showKeyboard() {
    _clearTimer?.cancel();
    _typedText = '';
    _textController.value = const TextEditingValue(
      text: _pad,
      selection: TextSelection.collapsed(offset: _pad.length),
    );
    setState(() {
      _keyboardOn = true;
      _displayText = '|';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textFieldNode.requestFocus();
    });
  }

  void _onTextChanged(String newString) {
    final delta = newString.length - _pad.length;

    if (delta > 0) {
      // Characters added — may be more than one (autocomplete, paste).
      final added = newString.substring(_pad.length);
      for (final char in added.split('')) {
        ServerConnector.sendInput(Input.keyboardCharacter(text: char));
      }
      _typedText += added;
    } else if (delta < 0) {
      // Characters deleted — send one backspace per deleted character.
      // Hold-backspace or word-delete can remove several at once.
      final deleteCount = -delta;
      for (int i = 0; i < deleteCount; i++) {
        ServerConnector.sendInput(Input.keyboardBackSpace());
      }
      _typedText = _typedText.length > deleteCount
          ? _typedText.substring(0, _typedText.length - deleteCount)
          : '';
    }

    // Always reset to pad so hold-backspace never exhausts the buffer.
    // Setting the controller programmatically does not trigger onChanged.
    _textController.value = const TextEditingValue(
      text: _pad,
      selection: TextSelection.collapsed(offset: _pad.length),
    );

    setState(() => _displayText = _typedText.isEmpty ? '|' : _typedText);
  }

  void _onSubmitted(String value) {
    ServerConnector.sendInput(Input.keyboardEnter());
    _typedText = '';
    _textController.value = const TextEditingValue(
      text: _pad,
      selection: TextSelection.collapsed(offset: _pad.length),
    );
    setState(() => _displayText = '|');
  }
}
