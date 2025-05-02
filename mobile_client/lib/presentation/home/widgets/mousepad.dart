import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_client/data/services/input.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';
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

  // --------- MOUSE EVENT HANDLERS -------- //
  void _handleMouseMove(ScaleUpdateDetails details) {
    var offset = details.focalPointDelta;
    var x = offset.dx.abs() < 1 ? (2 * offset.dx) : offset.dx;
    var y = offset.dy.abs() < 1 ? (2 * offset.dy) : offset.dy;
    var input = Input.mouseMove(move_x: x.toInt(), move_y: y.toInt());
    ServerConnector.sendInput(input);
  }

  void _handleLongPressMove(LongPressMoveUpdateDetails details) {
    var offset = details.localOffsetFromOrigin;
    var input =
        Input.mouseMove(move_x: offset.dx.toInt(), move_y: offset.dy.toInt());
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

  void _handleLongPress() {
    // var input = Input.setHold();
    // connector.sendInput(input);
  }

  void _handleLongPressUp() {
    // var input = Input.setRelease();
    // connector.sendInput(input);
  }


  // --------- FINGER GESTURES HANDLERS -------- //
  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 2) {
      isTwoFingerSwipe = true;
      pointerLocationY = details.focalPoint.dy;
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (isTwoFingerSwipe && details.pointerCount == 2) {
      _handleScroll(details);
    }
    else if (details.pointerCount == 1) {
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
        // MousePad
        GestureDetector(
          onTap: _handleMouseClick,
          // onLongPressMoveUpdate: _handleLongPressMove,
          // double finger scroll
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
