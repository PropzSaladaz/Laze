import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/dashed_border.dart';

import '../../../services/server_connector.dart';

class MousePad extends StatefulWidget {
  final bool fullscreen;
  final int sensitivity;

  const MousePad({
    super.key,
    required this.fullscreen,
    required this.sensitivity,
  });

  @override
  State<MousePad> createState() => _MousePadState();
}

class _FullscreenMousePadPage extends StatefulWidget {
  final int sensitivity;

  const _FullscreenMousePadPage({required this.sensitivity});

  @override
  State<_FullscreenMousePadPage> createState() =>
      _FullscreenMousePadPageState();
}

class _FullscreenMousePadPageState extends State<_FullscreenMousePadPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: appColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: MousePad(
            fullscreen: true,
            sensitivity: widget.sensitivity,
          ),
        ),
      ),
    );
  }
}

class _MousePadState extends State<MousePad> {
  bool _isTwoFingerTouch = false;
  bool _hasScrolledTwoFinger = false;
  DateTime? _twoFingerStartTime;
  int _maxPointerCount = 0;

  bool _isThreeFingerSwipe = false;
  bool _hasTriggeredThreeFinger = false;
  double _accumulatedThreeFingerY = 0.0;

  double pointerLocationY = 0.0;

  // Sub-pixel accumulation
  double _accumulatedX = 0.0;
  double _accumulatedY = 0.0;
  double _accumulatedScrollY = 0.0;

  // Drag mode state
  bool _isDragging = false;
  Timer? _longPressTimer;
  Offset? _initialTouchPosition;
  static const _longPressDuration = Duration(milliseconds: 400);
  static const _movementThreshold =
      3.0; // pixels - very small, any real movement cancels

  // 2-finger tap detection (done at the raw pointer level to beat the gesture arena)
  int _activePointers = 0;
  int _maxActivePointers = 0;
  DateTime? _firstPointerDownTime;
  bool _suppressNextTap = false;

  // --------- MOUSE EVENT HANDLERS -------- //
  void _handleMouseMove(ScaleUpdateDetails details) {
    var offset = details.focalPointDelta;

    // Apply sensitivity locally
    // Default base sensitivity on server was 1, so we map our new sensitivity directly
    double sensitivityMultiplier = widget.sensitivity.toDouble();
    double scaledDx = offset.dx * sensitivityMultiplier;
    double scaledDy = offset.dy * sensitivityMultiplier;

    // Calculate speed based on the SCALED movement
    double scaledSpeed = math.sqrt(scaledDx * scaledDx + scaledDy * scaledDy);

    // Power function acceleration curve
    // Similar to standard mouse acceleration curves (e.g. Windows/macOS)
    // gain = 1 + (speed ^ exponent)
    double acceleration = 1.0;

    // Only accelerate if moving fast enough to avoid noise
    if (scaledSpeed > 1.0) {
      // Exponent controls the curve shape.
      // < 1.0 gives "early" acceleration (fast rise)
      // > 1.0 gives "late" acceleration (slow rise then fast)
      const double exponent = 1.2;
      acceleration = 1.0 + (math.pow(scaledSpeed, exponent) * 0.01);

      // Cap max acceleration
      if (acceleration > 5.0) acceleration = 5.0;
    }

    // Apply acceleration to the ALREADY scaled sensitivity
    _accumulatedX += scaledDx * acceleration;
    _accumulatedY += scaledDy * acceleration;

    // Extract integer part to send
    int rawX = _accumulatedX.truncate();
    int rawY = _accumulatedY.truncate();

    // If we have enough movement to send a pixel
    if (rawX != 0 || rawY != 0) {
      // Clamp to signed byte range [-127, 127] to match protocol expectations
      // (though dart sends full ints, the protocol might squash them or protocol doc says byte)
      // data/services/input.dart sends [3, move_x, move_y] as bytes.
      // So we MUST clamp to [-128, 127] or similar.
      int sendX = rawX.clamp(-127, 127);
      int sendY = rawY.clamp(-127, 127);

      // Subtract only what we're sending to preserve the true remainder
      // This fixes a bug where clamping would discard the excess movement
      _accumulatedX -= sendX;
      _accumulatedY -= sendY;

      var input = Input.mouseMove(move_x: sendX, move_y: sendY);
      ServerConnector.sendMotionInput(input);
    }
  }

  void _processScrollDelta(double dy) {
    double swipeSense = 2.0;

    // Accumulate the scaled delta
    // Inverse direction: movement up (negative dy) -> scroll down (negative scroll value, content moves up)
    double delta = -(dy / swipeSense);
    _accumulatedScrollY += delta;

    // Extract integer part to send
    int scrollAmount = _accumulatedScrollY.truncate();

    if (scrollAmount != 0) {
      _hasScrolledTwoFinger = true;
      ServerConnector.sendMotionInput(Input.scroll(amount: scrollAmount));
      // Retain remainder
      _accumulatedScrollY -= scrollAmount;
    }
  }

  void _handleMouseScroll(DragUpdateDetails details) {
    _processScrollDelta(details.delta.dy);
  }

  void _handleScroll(ScaleUpdateDetails details) {
    _processScrollDelta(details.focalPointDelta.dy);
  }

  void _handleMouseClick() {
    if (_suppressNextTap) {
      _suppressNextTap = false;
      return;
    }
    var input = Input.leftClick();
    ServerConnector.sendInput(input);
  }

  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _activateDragMode() {
    if (!_isDragging) {
      _isDragging = true;
      ServerConnector.sendInput(Input.mouseDown());
    }
  }

  void _deactivateDragMode() {
    if (_isDragging) {
      _isDragging = false;
      ServerConnector.sendInput(Input.mouseUp());
    }
  }

  // --------- RAW POINTER HANDLERS (for long press detection) -------- //
  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    _maxActivePointers = math.max(_maxActivePointers, _activePointers);
    _firstPointerDownTime ??= DateTime.now();

    if (_activePointers == 1) {
      // Only set up long-press timer for single-finger
      _initialTouchPosition = event.position;
      _cancelLongPressTimer();
      _longPressTimer = Timer(_longPressDuration, () {
        if (_activePointers == 1) _activateDragMode();
      });
    } else {
      // Multi-finger: cancel long press
      _cancelLongPressTimer();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    // Cancel timer if ANY movement detected
    if (_initialTouchPosition != null && _longPressTimer != null) {
      final distance = (event.position - _initialTouchPosition!).distance;
      if (distance > _movementThreshold) {
        _cancelLongPressTimer();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = math.max(0, _activePointers - 1);

    if (_activePointers == 0) {
      // All fingers lifted — check for 2-finger tap
      final elapsed = _firstPointerDownTime != null
          ? DateTime.now().difference(_firstPointerDownTime!).inMilliseconds
          : 999;
      if (_maxActivePointers == 2 && !_hasScrolledTwoFinger && elapsed < 400) {
        _suppressNextTap = true;
        ServerConnector.sendInput(Input.rightClick());
      }

      // Reset pointer tracking
      _maxActivePointers = 0;
      _firstPointerDownTime = null;
      _cancelLongPressTimer();
      _initialTouchPosition = null;
      _deactivateDragMode();
    }
  }

  // --------- FINGER GESTURES HANDLERS -------- //
  void _handleScaleStart(ScaleStartDetails details) {
    _maxPointerCount = math.max(_maxPointerCount, details.pointerCount);

    if (details.pointerCount == 2) {
      _isTwoFingerTouch = true;
      _hasScrolledTwoFinger = false;
      _twoFingerStartTime = DateTime.now();
      pointerLocationY = details.focalPoint.dy;
      // Cancel long press timer when second finger added
      _cancelLongPressTimer();
    } else if (details.pointerCount == 3) {
      _isThreeFingerSwipe = true;
      _hasTriggeredThreeFinger = false;
      _accumulatedThreeFingerY = 0.0;
      _cancelLongPressTimer();
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    _maxPointerCount = math.max(_maxPointerCount, details.pointerCount);

    if (_isThreeFingerSwipe && _maxPointerCount == 3) {
      if (!_hasTriggeredThreeFinger) {
        _accumulatedThreeFingerY += details.focalPointDelta.dy;
        // Trigger if swipe distance exceeds a threshold (e.g. 40 pixels up or down)
        if (_accumulatedThreeFingerY.abs() > 40.0) {
          _hasTriggeredThreeFinger = true;
          ServerConnector.sendInput(Input.altTab());
        }
      }
    } else if (_isTwoFingerTouch && _maxPointerCount == 2) {
      _handleScroll(details);
    } else if (_maxPointerCount == 1) {
      _handleMouseMove(details);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    final elapsed = _twoFingerStartTime != null
        ? DateTime.now().difference(_twoFingerStartTime!).inMilliseconds
        : -1;

    // A tap is registered if the max fingers on screen was 2,
    // they didn't scroll, and they were released quickly.
    if (_maxPointerCount == 2 &&
        !_hasScrolledTwoFinger &&
        _twoFingerStartTime != null &&
        elapsed < 300) {
      ServerConnector.sendInput(Input.rightClick());
    }

    // Always reset all gesture state when scale gesture ends
    _isTwoFingerTouch = false;
    _isThreeFingerSwipe = false;
    _hasTriggeredThreeFinger = false;
    _hasScrolledTwoFinger = false;
    _twoFingerStartTime = null;
    _maxPointerCount = 0;
  }

  void _showGestureGuide(BuildContext context, AppColors appColors) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appColors.surface_1,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.of(sheetContext).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gesture guide',
              style: TextStyle(
                color: appColors.text,
                fontSize: Dimens.text.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _GestureHint(
              icon: Icons.touch_app_outlined,
              text: 'Tap to left click',
              appColors: appColors,
            ),
            _GestureHint(
              icon: Icons.swipe_vertical_outlined,
              text: 'Two fingers to scroll',
              appColors: appColors,
            ),
            _GestureHint(
              icon: Icons.ads_click,
              text: 'Tap with two fingers for right click',
              appColors: appColors,
            ),
            _GestureHint(
              icon: Icons.swap_horiz,
              text: 'Three-finger swipe for Alt-Tab',
              appColors: appColors,
            ),
            _GestureHint(
              icon: Icons.pan_tool_outlined,
              text: 'Long press to drag',
              appColors: appColors,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    const rotationAngle = -90 * math.pi / 180;
    final screenSize = MediaQuery.of(context).size;
    final borderRadius = BorderRadius.circular(25);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : screenSize.height;
        // Use the bounded constraint height when the parent provides one (e.g.
        // when wrapped in Expanded). Fall back to 40% of screen height only
        // when the height is truly unbounded.
        final padHeight = widget.fullscreen
            ? availableHeight
            : (constraints.hasBoundedHeight && constraints.maxHeight > 0
                ? constraints.maxHeight
                : 0.40 * screenSize.height);
        final scrollHeight = widget.fullscreen ? availableHeight : padHeight;

        return SizedBox(
          height: padHeight,
          child: Stack(
            children: [
              Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                child: GestureDetector(
                  onTap: _handleMouseClick,
                  // scale gestures handle mouse move and scroll
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onScaleEnd: _handleScaleEnd,
                  child: Stack(
                    children: [
                      CustomPaint(
                        foregroundPainter: DashedBorderPainter(
                          color: appColors.textMuted,
                          strokeWidth: 1,
                          dashLength: 6,
                          dashGap: 6,
                          borderRadius: 25,
                        ),
                        child: ClipRRect(
                          borderRadius: borderRadius,
                          child: Container(
                            width: double.infinity,
                            height: padHeight,
                            decoration: BoxDecoration(
                              color: appColors.surface_1,
                              borderRadius: borderRadius,
                            ),
                          ),
                        ),
                      ),
                      if (!widget.fullscreen)
                        Positioned(
                          left: -50,
                          top: 110,
                          child: Transform.rotate(
                            angle: rotationAngle,
                            child: Text(
                              'MOUSEPAD',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 24,
                                color: appColors.textMuted,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: widget.fullscreen ? 25 : 10,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _handleMouseScroll(details);
                  },
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 60,
                        height: scrollHeight,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: FractionallySizedBox(
                            heightFactor: widget.fullscreen ? 0.85 : 0.93,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: appColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!widget.fullscreen)
                        Positioned(
                          bottom: 70,
                          right: -25,
                          child: Transform.rotate(
                            angle: rotationAngle,
                            child: Text(
                              'SCROLL',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                color: appColors.textMuted,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen),
                  color: appColors.textMuted,
                  iconSize: Dimens.icon.large,
                  onPressed: () {
                    widget.fullscreen
                        ? Navigator.of(context).pop()
                        : Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => _FullscreenMousePadPage(
                                sensitivity: widget.sensitivity,
                              ),
                            ),
                          );
                  },
                ),
              ),
              Positioned(
                left: 60,
                bottom: 12,
                child: IconButton(
                  icon: const Icon(Icons.help_outline),
                  color: appColors.textMuted,
                  iconSize: Dimens.icon.medium,
                  tooltip: 'Gesture guide',
                  onPressed: () => _showGestureGuide(context, appColors),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GestureHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final AppColors appColors;

  const _GestureHint({
    required this.icon,
    required this.text,
    required this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: appColors.surface_2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: appColors.divider, width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: appColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: appColors.text,
                fontSize: Dimens.text.small,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
