import 'package:flutter/material.dart';
import 'package:mobile_client/color_constants.dart';
import 'dart:math' as math;

class MousePad extends StatelessWidget {
  const MousePad({super.key});

  void handleMouseDrag(DragUpdateDetails details) {
    var offset = details.delta;
    print("Offset: $offset");
  }

  @override
  Widget build(BuildContext context) {
    const rotationAngle = -90 * math.pi / 180;
    Size screenSize = MediaQuery.of(context).size;
    return Stack(
      children: [
        // MousePad
        GestureDetector(
          onPanUpdate: handleMouseDrag,
          child: Stack(
            children: [
              // main mousepad
              Container(
                width: double.infinity,
                height: 0.4 * screenSize.height,
                decoration: BoxDecoration(
                  border: Border.all(color: ColorConstants.border, width: 3),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
              ),

              // mousepad text
              Positioned(
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
              )
            ],
          ),
        ),

        // Scroll
        Positioned(
          right: 10,
          child: GestureDetector(
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: 0.40 * screenSize.height,
                  padding: const EdgeInsets.all(2),
                  child: FractionallySizedBox(
                    heightFactor: 0.93,
                    child: Container(
                        decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: ColorConstants.scroll,
                    )),
                  ),
                ),
                Positioned(
                  bottom: 70,
                  right: -27,
                  child: Transform.rotate(
                    angle: rotationAngle,
                    child: const Text("SCROLL",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 30,
                            color: ColorConstants.scrollText)),
                  ),
                )
              ],
            ),
          ),
        ),

        // full screen button
        const Positioned(
            left: 10,
            bottom: 10,
            child: Icon(
              Icons.fullscreen,
              color: ColorConstants.mousepadText,
              size: 80,
            ))
      ],
    );
  }
}
