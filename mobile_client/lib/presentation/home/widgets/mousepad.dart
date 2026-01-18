import 'dart:async';

import 'package:flutter/material.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/core/themes/colors.dart';
import 'dart:math' as math;

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

class _MousePadState extends State<MousePad> {
  bool isTwoFingerSwipe = false;
  bool isThreeFingerSwipe = false;
  double pointerLocationY = 0.0;
  Offset? _threeFingerSwipeStart;
  
  // Sub-pixel accumulation
  double _accumulatedX = 0.0;
  double _accumulatedY = 0.0;
  double _accumulatedScrollY = 0.0;

  // Drag mode state
  bool _isDragging = false;
  Timer? _longPressTimer;
  Offset? _initialTouchPosition;
  static const _longPressDuration = Duration(milliseconds: 400);
  static const _movementThreshold = 3.0; // pixels - very small, any real movement cancels
  static const _threeFingerSwipeThreshold = 50.0; // pixels - minimum swipe distance

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
      ServerConnector.sendInput(input);
    }
  }
  void _handleMouseScroll(DragUpdateDetails details) {
    double scrollAmountY = details.delta.dy; 
    double swipeSense = 2.0;

    // Accumulate the scaled delta
    // Inverse direction: drag up (negative dy) -> scroll down (negative scroll value, content moves up)
    // Same logic as two-finger scroll
    double delta = -(scrollAmountY / swipeSense);
    _accumulatedScrollY += delta;

    // Extract integer part to send
    int scrollAmount = _accumulatedScrollY.truncate();

    if (scrollAmount != 0) {
      ServerConnector.sendInput(Input.scroll(amount: scrollAmount));
      // Retain remainder
      _accumulatedScrollY -= scrollAmount;
    }
  }

  void _handleScroll(ScaleUpdateDetails details) {
    double scrollAmountY = details.focalPointDelta.dy; 
    double swipeSense = 2.0;

    // Accumulate the scaled delta
    // Inverse direction: fingers up -> scroll down (positive input usually means down/right in many protocols, 
    // but here we invert it based on previous logic -(scrollAmountY/swipeSense))
    double delta = -(scrollAmountY / swipeSense);
    _accumulatedScrollY += delta;

    // Extract integer part to send
    int scrollAmount = _accumulatedScrollY.truncate();

    if (scrollAmount != 0) {
      ServerConnector.sendInput(Input.scroll(amount: scrollAmount));
      // Retain remainder
      _accumulatedScrollY -= scrollAmount;
    }
  }

  void _handleMouseClick() {
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
    _initialTouchPosition = event.position;
    _cancelLongPressTimer();
    _longPressTimer = Timer(_longPressDuration, () {
      _activateDragMode();
    });
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
    _cancelLongPressTimer();
    _initialTouchPosition = null;
    _deactivateDragMode();
  }

  // --------- FINGER GESTURES HANDLERS -------- //
  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 3) {
      isThreeFingerSwipe = true;
      _threeFingerSwipeStart = details.focalPoint;
      // Cancel long press timer when three fingers detected
      _cancelLongPressTimer();
    } else if (details.pointerCount == 2) {
      isTwoFingerSwipe = true;
      pointerLocationY = details.focalPoint.dy;
      // Cancel long press timer when second finger added
      _cancelLongPressTimer();
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (isThreeFingerSwipe && details.pointerCount == 3) {
      // 3-finger swipe is in progress, don't process updates yet
      // We'll handle it in _handleScaleEnd
    } else if (isTwoFingerSwipe && details.pointerCount == 2) {
      _handleScroll(details);
    } else if (details.pointerCount == 1) {
      _handleMouseMove(details);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (isThreeFingerSwipe && _threeFingerSwipeStart != null) {
      // Calculate the swipe distance and direction
      // Note: details.velocity is more reliable but we use accumulated position
      // Get current focal point from the last update
      final dy = details.velocity.pixelsPerSecond.dy;
      
      // Determine if swipe was significant and in which direction
      if (dy.abs() > 100) { // velocity threshold
        if (dy < 0) {
          // Swiped up (negative velocity)
          ServerConnector.sendInput(Input.threeFingerSwipeUp());
        } else {
          // Swiped down (positive velocity)
          ServerConnector.sendInput(Input.threeFingerSwipeDown());
        }
      }
      
      isThreeFingerSwipe = false;
      _threeFingerSwipeStart = null;
    }
    
    isTwoFingerSwipe = false;
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    const rotationAngle = -90 * math.pi / 180;
    Size screenSize = MediaQuery.of(context).size;
    double scrollHeight =
        widget.fullscreen ? screenSize.height : 0.40 * screenSize.height;
    return Stack(
      children: [
        // MousePad - wrapped in Listener for raw pointer events
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
                // main mousepad
                Container(
                  width: double.infinity,
                  height: widget.fullscreen ? double.infinity : 0.4 * screenSize.height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: customColors!.border, 
                      width: 3,
                    ),
                  ),
                ),
                () {
                  // mousepad text
                  if (widget.fullscreen) {
                    return const SizedBox();
                  } else {
                    return Positioned(
                      left: -65,
                      top: 105,
                      child: Transform.rotate(
                        angle: rotationAngle,
                        child: const Text(
                          "MOUSEPAD",
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 40,
                              // color: ColorConstants.mousepadText,
                          ),
                        ),
                      ),
                    );
                  }
                }(),
                // mousepad text
              ],
            ),
          ),
        ),

        // Scroll
        Positioned(
          right: widget.fullscreen ? 25 : 10,
          child: GestureDetector(
            onPanUpdate: (details) {
              _handleMouseScroll(details);
            },
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: scrollHeight,
                  padding: const EdgeInsets.all(2),
                  child: FractionallySizedBox(
                    heightFactor: widget.fullscreen ? 0.85 : 0.93,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: customColors.border,
                      ),
                    ),
                  ),
                ),
                () {
                  // scroll text
                  if (widget.fullscreen) {
                    return const SizedBox();
                  } else {
                    return Positioned(
                      bottom: 70,
                      right: -27,
                      child: Transform.rotate(
                        angle: rotationAngle,
                        child: const Text(
                          "SCROLL",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 30,
                              // color: ColorConstants.scrollText
                            ),
                        ),
                      ),
                    );
                  }
                }(),
              ],
            ),
          ),
        ),

        // full screen button
        Positioned(
          left: 0,
          bottom: 0,
          child: IconButton(
            icon: const Icon(Icons.fullscreen),
            // color: ColorConstants.border,
            iconSize: 64,
            onPressed: () {
              widget.fullscreen
                  ? Navigator.of(context).pop()
                  : Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MousePad(
                          fullscreen: true,
                          sensitivity: widget.sensitivity,
                        ),
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }
}
