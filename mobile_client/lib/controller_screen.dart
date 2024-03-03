import 'package:flutter/material.dart';
import 'package:mobile_client/color_constants.dart';
import 'package:mobile_client/mousepad.dart';
import 'package:mobile_client/styled-button.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  static const String NOT_CONNECTED = "NOT CONNECTED";
  static const String CONNECTED = "CONNECTED";

  String connectionStatus = NOT_CONNECTED;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("blablo"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 24, vertical: 24),
          alignment: Alignment.topCenter,
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      connectionStatus,
                      style: const TextStyle(
                        color: ColorConstants.mainText,
                        fontSize: 35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const StyledButton(
                      icon: Icons.power_settings_new,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 23,
              ),
              const MousePad(),
            ],
          ),
        ),
      ),
    );
  }
}
