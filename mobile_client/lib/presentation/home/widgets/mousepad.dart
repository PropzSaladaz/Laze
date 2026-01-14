import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laze/data/services/input.dart';
import 'package:laze/presentation/core/themes/colors.dart';
import 'dart:math' as math;

import '../../../services/server_connector.dart';

class MousePad extends StatefulWidget {
  final bool fullscreen;

  const MousePad({
    super.key, 
    required this.fullscreen
  });

  @override
  State<MousePad> createState() => _MousePadState();
}

class _MousePadState extends State<MousePad> {
  bool isTwoFingerSwipe = false;
  double pointerLocationY = 0.0;

  // Drag mode state
  bool _isDragging = false;
  Timer? _longPressTimer;
  Offset? _initialTouchPosition;
  static const _longPressDuration = Duration(milliseconds: 400);
  static const _movementThreshold = 3.0; // pixels - very small, any real movement cancels

  // --------- MOUSE EVENT HANDLERS -------- //
  void _handleMouseMove(ScaleUpdateDetails details) {
    var offset = details.focalPointDelta;
    var x = offset.dx.abs() < 1 ? (2 * offset.dx) : offset.dx;
    var y = offset.dy.abs() < 1 ? (2 * offset.dy) : offset.dy;
    var input = Input.mouseMove(move_x: x.toInt(), move_y: y.toInt());
    ServerConnector.sendInput(input);
  }
  void _handleMouseScroll(DragUpdateDetails details, double midPos) {
    var offset = details.localPosition.dy;
    if (offset.toInt() % 3 == 0) {
      sleep(const Duration(milliseconds: 10));
      double amount = (offset - midPos) / midPos;
      if (amount > 0) {
        ServerConnector.sendInput(Input.scroll(amount: -1));
      } else {
        ServerConnector.sendInput(Input.scroll(amount: 1));
      }
    }
  }

  void _handleScroll(ScaleUpdateDetails details) {
    double scrollAmountY = details.focalPointDelta.dy; 
    double swipeSense = 2.0;
    // if there is some movement, scroll by the inverse of that amount.
    // If fingers go up -> scroll down.
    if (scrollAmountY != 0) {
      ServerConnector.sendInput(Input.scroll(amount: -(scrollAmountY/swipeSense).toInt()));
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
    double midPos = scrollHeight / 2;
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
              _handleMouseScroll(details, midPos);
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
                        builder: (context) => const MousePad(
                          fullscreen: true,
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
