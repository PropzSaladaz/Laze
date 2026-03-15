import 'dart:async';

import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

typedef Callback = void Function();

class StyledButton extends StatefulWidget {
  final IconData icon;
  final Callback onPressed;
  final bool isClicked;

  const StyledButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isClicked = false,
  });

  @override
  State<StyledButton> createState() => _StyledButtonState();
}

class _StyledButtonState extends State<StyledButton> {
  bool _isPressed = false;
  DateTime? _pressedAt;
  Timer? _releaseTimer;

  static const _minHoldMs = 150;
  static const _pressDownDuration = Duration(milliseconds: 60);
  static const _releaseUpDuration = Duration(milliseconds: 200);

  static const _shadows = [
    BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.84), offset: Offset(-2, -1), blurRadius: 5),
    BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.77), offset: Offset(-8, -3), blurRadius: 9),
    BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.68), offset: Offset(-18, -8), blurRadius: 12),
    BoxShadow(color: Color.fromRGBO(95, 95, 95, 0.09), offset: Offset(6, 1), blurRadius: 6),
    BoxShadow(color: Color.fromRGBO(95, 95, 95, 0.1), offset: Offset(1, 0), blurRadius: 3),
  ];

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown() {
    _releaseTimer?.cancel();
    _pressedAt = DateTime.now();
    setState(() => _isPressed = true);
  }

  void _onPointerUp() {
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

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final flat = _isPressed || widget.isClicked;

    return Listener(
      onPointerDown: (_) => _onPointerDown(),
      onPointerUp: (_) => _onPointerUp(),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: _isPressed ? _pressDownDuration : _releaseUpDuration,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.isClicked ? appColors.primary : appColors.bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isClicked ? appColors.primary : appColors.border,
            width: 6,
          ),
          boxShadow: flat ? null : _shadows,
        ),
        child: IconButton(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon),
          iconSize: Dimens.icon.medium,
          color: widget.isClicked ? appColors.onPrimary : appColors.textMuted,
        ),
      ),
    );
  }
}
