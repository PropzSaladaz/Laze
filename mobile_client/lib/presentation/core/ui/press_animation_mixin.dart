import 'dart:async';

import 'package:flutter/material.dart';

/// Mixin that adds a press-hold-release animation to a [State].
///
/// Use [isPressed] to drive visual changes, and wire [handlePointerDown],
/// [handlePointerUp], and [handlePointerCancel] to a [Listener] widget.
///
/// The mixin guarantees a minimum visual hold of [_minHoldMs] milliseconds
/// so even quick taps produce a visible feedback pulse.
mixin PressAnimationMixin<T extends StatefulWidget> on State<T> {
  bool _isPressed = false;
  DateTime? _pressedAt;
  Timer? _releaseTimer;

  static const int _minHoldMs = 90;
  Duration get pressDownDuration => const Duration(milliseconds: 45);
  Duration get pressUpDuration => const Duration(milliseconds: 110);

  bool get isPressed => _isPressed;

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  void handlePointerDown() {
    _releaseTimer?.cancel();
    _pressedAt = DateTime.now();
    setState(() => _isPressed = true);
  }

  void handlePointerUp() {
    final elapsed = DateTime.now().difference(_pressedAt!).inMilliseconds;
    final delay = _minHoldMs - elapsed;
    if (delay > 0) {
      _releaseTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted) setState(() => _isPressed = false);
      });
    } else {
      setState(() => _isPressed = false);
    }
  }

  void handlePointerCancel() {
    _releaseTimer?.cancel();
    setState(() => _isPressed = false);
  }
}
