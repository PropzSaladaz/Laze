import 'dart:async';

import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

typedef Callback = void Function();

class StyledButton extends StatefulWidget {
  final IconData icon;
  final Callback onPressed;
  final bool isClicked;
  final double? width;
  final double? height;
  final double? iconSize;
  final EdgeInsetsGeometry margin;

  const StyledButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isClicked = false,
    this.width,
    this.height,
    this.iconSize,
    this.margin = const EdgeInsets.all(10),
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
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.isClicked ? appColors.primary : appColors.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: widget.isClicked ? appColors.primary : appColors.border,
            width: 6,
          ),
          boxShadow: flat ? null : AppShadows.raisedControl,
        ),
        child: IconButton(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon),
          padding: EdgeInsets.zero,
          iconSize: widget.iconSize ?? Dimens.icon.medium,
          color: widget.isClicked ? appColors.onPrimary : appColors.textMuted,
        ),
      ),
    );
  }
}
