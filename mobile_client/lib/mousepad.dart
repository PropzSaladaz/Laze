import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_client/client/dto/input.dart';
import 'package:mobile_client/color_constants.dart';
import 'dart:math' as math;

import 'client/server_connector.dart';

class MousePad extends StatelessWidget {
  final ServerConnector connector;
  final bool fullscreen;

  const MousePad(
      {super.key, required this.connector, required this.fullscreen});

  void _handleMouseDrag(DragUpdateDetails details) {
    var offset = details.delta;
    var x = offset.dx.abs() < 1 ? (2 * offset.dx) : offset.dx;
    var y = offset.dy.abs() < 1 ? (2 * offset.dy) : offset.dy;
    Input input = Input.mouseMove(move_x: x.toInt(), move_y: y.toInt());
    connector.sendInput(input);
  }

  void _handleLongPressMove(LongPressMoveUpdateDetails details) {
    var offset = details.localOffsetFromOrigin;
    Input input =
        Input.mouseMove(move_x: offset.dx.toInt(), move_y: offset.dy.toInt());
    connector.sendInput(input);
  }

  void _handleMouseScroll(DragUpdateDetails details, double midPos) {
    var offset = details.localPosition.dy;
    if (offset.toInt() % 3 == 0) {
      sleep(const Duration(milliseconds: 10));
      double amount = (offset - midPos) / midPos;
      if (amount > 0) {
        connector.sendInput(Input.scroll(amount: -1));
      } else {
        connector.sendInput(Input.scroll(amount: 1));
      }
    }
  }

  void _handleMouseClick() {
    Input input = Input.leftClick();
    connector.sendInput(input);
  }

  void _handleLongPress() {
    Input input = Input.setHold();
    connector.sendInput(input);
  }

  void _handleLongPressUp() {
    Input input = Input.setRelease();
    connector.sendInput(input);
  }

  @override
  Widget build(BuildContext context) {
    const rotationAngle = -90 * math.pi / 180;
    Size screenSize = MediaQuery.of(context).size;
    double scrollHeight =
        fullscreen ? screenSize.height : 0.40 * screenSize.height;
    double midPos = scrollHeight / 2;
    return Stack(
      children: [
        // MousePad
        GestureDetector(
          onPanUpdate: _handleMouseDrag,
          onTap: _handleMouseClick,
          onPanCancel: _handleLongPressUp,
          onLongPressMoveUpdate: _handleLongPressMove,
          child: Stack(
            children: [
              // main mousepad
              Container(
                width: double.infinity,
                height: fullscreen ? double.infinity : 0.4 * screenSize.height,
                decoration: BoxDecoration(
                  border: Border.all(color: ColorConstants.border, width: 3),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
              ),
              () {
                // mousepad text
                if (fullscreen) {
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
                            color: ColorConstants.mousepadText),
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
          right: fullscreen ? 25 : 10,
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
                    heightFactor: fullscreen ? 0.85 : 0.93,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: ColorConstants.scroll,
                      ),
                    ),
                  ),
                ),
                () {
                  // scroll text
                  if (fullscreen) {
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
                              color: ColorConstants.scrollText),
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
            color: ColorConstants.border,
            iconSize: 64,
            onPressed: () {
              fullscreen
                  ? Navigator.of(context).pop()
                  : Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MousePad(
                          connector: connector,
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
