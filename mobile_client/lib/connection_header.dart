import 'package:flutter/material.dart';
import 'package:mobile_client/buttons/styled_button.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/color_constants.dart';

typedef Callback = void Function();

class ConnectionHeader extends StatefulWidget {
  final String connectionStatus;
  final Callback connect;
  final Callback disconnect;
  final Callback turnOffPc;

  const ConnectionHeader(
      {super.key,
      required this.connectionStatus,
      required this.connect,
      required this.disconnect,
      required this.turnOffPc});

  @override
  State<ConnectionHeader> createState() => _ConnectionHeaderState();
}

class _ConnectionHeaderState extends State<ConnectionHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.connectionStatus,
            style: const TextStyle(
              color: ColorConstants.mainText,
              fontSize: 35,
              fontWeight: FontWeight.w500,
            ),
          ),
          () {
            // CONNECTED -> button used to disconnect
            if (widget.connectionStatus == ServerConnector.CONNECTED) {
              return StyledButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => _disconnectPopup());
                },
                icon: Icons.power_settings_new,
              );
            } else {
              // NOT CONNECTED -> button used to connect
              return StyledButton(
                onPressed: widget.connect,
                icon: Icons.screen_search_desktop_outlined,
              );
            }
          }()
        ],
      ),
    );
  }

  Widget _disconnectPopup() {
    return AlertDialog(
      alignment: Alignment.center,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: ColorConstants.background,
      title: const Text("Disconnect"),
      actions: [
        TextButton(
          onPressed: () {
            widget.disconnect();
            Navigator.of(context).pop();
          },
          child: const Text(
            "Disconnect",
          ),
        ),
        TextButton(
          onPressed: () {
            widget.turnOffPc();
            Navigator.of(context).pop();
          },
          child: const Text(
            "Turn OFF PC",
          ),
        )
      ],
    );
  }
}
