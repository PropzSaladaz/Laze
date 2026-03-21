import 'dart:async';

import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

typedef Callback = void Function();

class StyledLongButton extends StatefulWidget {
  final IconData iconUp;
  final IconData iconDown;
  final Callback? onPressedUp;
  final Callback onPressedDown;
  final String description;
  final bool? vertical;
  final double? width;
  final double? height;
  final double iconSize;
  final double descriptionFontSize;

  const StyledLongButton({
    super.key,
    required this.iconUp,
    required this.iconDown,
    required this.description,
    required this.onPressedDown,
    this.onPressedUp,
    this.vertical,
    this.width,
    this.height,
    this.iconSize = 45,
    this.descriptionFontSize = 20,
  });

  @override
  State<StyledLongButton> createState() => _StyledLongButtonState();
}

class _StyledLongButtonState extends State<StyledLongButton> {
  bool _pressedUp = false;
  bool _pressedDown = false;

  DateTime? _pressedUpAt;
  DateTime? _pressedDownAt;
  Timer? _releaseUpTimer;
  Timer? _releaseDownTimer;

  static const _minHoldMs = 150;
  static const _pressDownDuration = Duration(milliseconds: 60);
  static const _releaseUpDuration = Duration(milliseconds: 200);

  @override
  void dispose() {
    _releaseUpTimer?.cancel();
    _releaseDownTimer?.cancel();
    super.dispose();
  }

  void _onUpPointerDown() {
    _releaseUpTimer?.cancel();
    _pressedUpAt = DateTime.now();
    setState(() => _pressedUp = true);
  }

  void _onUpPointerUp() {
    final elapsed = DateTime.now().difference(_pressedUpAt!).inMilliseconds;
    final delay = _minHoldMs - elapsed;
    if (delay > 0) {
      _releaseUpTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted) setState(() => _pressedUp = false);
      });
    } else {
      setState(() => _pressedUp = false);
    }
  }

  void _onDownPointerDown() {
    _releaseDownTimer?.cancel();
    _pressedDownAt = DateTime.now();
    setState(() => _pressedDown = true);
  }

  void _onDownPointerUp() {
    final elapsed = DateTime.now().difference(_pressedDownAt!).inMilliseconds;
    final delay = _minHoldMs - elapsed;
    if (delay > 0) {
      _releaseDownTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted) setState(() => _pressedDown = false);
      });
    } else {
      setState(() => _pressedDown = false);
    }
  }

  Color _overlayColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color.fromRGBO(255, 255, 255, 0.08)
        : const Color.fromRGBO(0, 0, 0, 0.14);
  }

  Widget _pressOverlay({
    required bool pressed,
    required AlignmentGeometry align,
    required AlignmentGeometry gradientBegin,
    required Color color,
  }) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: pressed ? 1.0 : 0.0,
        duration: pressed ? _pressDownDuration : _releaseUpDuration,
        curve: pressed ? Curves.easeIn : Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Align(
            alignment: align,
            child: FractionallySizedBox(
              heightFactor: 0.5,
              widthFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: gradientBegin,
                    end: Alignment.center,
                    colors: [color, color.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _autoSpacing({required double spacing}) {
    if (widget.vertical != null && widget.vertical == true) {
      return SizedBox(height: spacing);
    }
    return SizedBox(width: spacing / 3);
  }

  Widget _buildLayout(BuildContext context, AppColors appColors) {
    if (widget.vertical != null && widget.vertical == true) {
      final overlayColor = _overlayColor(context);

      final column = Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Listener(
            onPointerDown: (_) => _onUpPointerDown(),
            onPointerUp: (_) => _onUpPointerUp(),
            onPointerCancel: (_) => setState(() => _pressedUp = false),
            child: AnimatedSlide(
              offset: _pressedUp ? const Offset(0, 0.06) : Offset.zero,
              duration: _pressedUp ? _pressDownDuration : _releaseUpDuration,
              curve: _pressedUp ? Curves.easeIn : Curves.easeOut,
              child: IconButton(
                onPressed: widget.onPressedUp,
                icon: Icon(widget.iconUp),
                iconSize: widget.iconSize,
                color: appColors.textMuted,
              ),
            ),
          ),
          _autoSpacing(spacing: 12),
          Text(
            widget.description,
            style: TextStyle(
              color: appColors.textMuted,
              fontSize: widget.descriptionFontSize,
            ),
          ),
          _autoSpacing(spacing: 12),
          Listener(
            onPointerDown: (_) => _onDownPointerDown(),
            onPointerUp: (_) => _onDownPointerUp(),
            onPointerCancel: (_) => setState(() => _pressedDown = false),
            child: AnimatedSlide(
              offset: _pressedDown ? const Offset(0, -0.06) : Offset.zero,
              duration: _pressedDown ? _pressDownDuration : _releaseUpDuration,
              curve: _pressedDown ? Curves.easeIn : Curves.easeOut,
              child: IconButton(
                onPressed: widget.onPressedDown,
                icon: Icon(widget.iconDown),
                iconSize: widget.iconSize,
                color: appColors.textMuted,
              ),
            ),
          ),
        ],
      );

      return Stack(
        fit: StackFit.expand,
        children: [
          column,
          _pressOverlay(
            pressed: _pressedUp,
            align: Alignment.topCenter,
            gradientBegin: Alignment.topCenter,
            color: overlayColor,
          ),
          _pressOverlay(
            pressed: _pressedDown,
            align: Alignment.bottomCenter,
            gradientBegin: Alignment.bottomCenter,
            color: overlayColor,
          ),
        ],
      );
    }

    return Row(
      children: [
        Listener(
          onPointerDown: (_) => _onDownPointerDown(),
          onPointerUp: (_) => _onDownPointerUp(),
          onPointerCancel: (_) => setState(() => _pressedDown = false),
          child: TextButton(
            style: ButtonStyle(
              overlayColor: WidgetStatePropertyAll(appColors.hover),
            ),
            onPressed: widget.onPressedDown,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
              child: Text(
                widget.description,
                style: TextStyle(
                  color: appColors.textMuted,
                  fontSize: widget.descriptionFontSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: widget.width,
      height: widget.height,
      margin: const EdgeInsets.all(10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: appColors.bg,
        borderRadius: BorderRadius.circular(50),
        boxShadow: AppShadows.raisedControl(appColors),
      ),
      child: _buildLayout(context, appColors),
    );
  }
}
