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
  static const _movementThreshold = 3.0; // pixels - very small, any real movement cancels

  // --------- MOUSE EVENT HANDLERS -------- //
  void _handleMouseMove(ScaleUpdateDetails details) {
    var offset = details.focalPointDelta;
    
    // Apply sensitivity locally
    // Default base sensitivity on server was 1, so we map our new sensitivity directly    // Calculate speed (distance per frame)
    double speed = offset.distance;
    
    // Calculate acceleration multiplier
    // Base is 1.0 (no acceleration)
    double acceleration = 1.0;
    
    // Simple linear acceleration curve
    // If moving faster than 1 logical pixel per frame, start accelerating
    if (speed > 1.0) {
      // Curve: Linear increase in gain based on speed
      // Adjust the 0.05 coefficient to tune how aggressive the acceleration is
      acceleration = 1.0 + (speed * 0.05);
      
      // Cap max acceleration to prevent uncontrollable flying
      if (acceleration > 3.0) acceleration = 3.0;
    }

    // Apply sensitivity AND acceleration
    double sensitivityMultiplier = widget.sensitivity.toDouble();
    _accumulatedX += offset.dx * sensitivityMultiplier * acceleration;
    _accumulatedY += offset.dy * sensitivityMultiplier * acceleration;
    
    // Extract integer part to send
    int moveX = _accumulatedX.truncate();
    int moveY = _accumulatedY.truncate();
    
    // If we have enough movement to send a pixel
    if (moveX != 0 || moveY != 0) {
      // Clamp to byte range if necessary, though typical usage won't exceed 127 in one frame
      // Logic for byte clamping happens inherently if we cast to int8/uint8, 
      // but let's just send it. The generic integer send might handle it, 
      // but Input.mouseMove usually expects int.
      // Important: Keep the remainder for next frame
      _accumulatedX -= moveX;
      _accumulatedY -= moveY;
      
      // Clamp to signed byte range [-127, 127] to match protocol expectations 
      // (though dart sends full ints, the protocol might squash them or protocol doc says byte)
      // data/services/input.dart sends [3, move_x, move_y] as bytes.
      // So we MUST clamp to [-128, 127] or similar.
      moveX = moveX.clamp(-127, 127);
      moveY = moveY.clamp(-127, 127);
      
      var input = Input.mouseMove(move_x: moveX, move_y: moveY);
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
    if (details.pointerCount == 2) {
      isTwoFingerSwipe = true;
      pointerLocationY = details.focalPoint.dy;
      // Cancel long press timer when second finger added
      _cancelLongPressTimer();
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (isTwoFingerSwipe && details.pointerCount == 2) {
      _handleScroll(details);
    } else if (details.pointerCount == 1) {
      _handleMouseMove(details);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
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
