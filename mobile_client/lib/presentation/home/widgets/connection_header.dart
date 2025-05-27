import 'package:flutter/material.dart';
import 'package:mobile_client/presentation/core/ui/styled_button.dart';
import 'package:mobile_client/services/server_connector.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';

typedef Callback = void Function();

class ConnectionHeader extends StatefulWidget {
  final String connectionStatus;
  final Callback connect;
  final Callback cancelSearch;
  final Callback disconnect;
  final Callback turnOffPc;

  const ConnectionHeader(
      {super.key,
      required this.connectionStatus,
      required this.connect,
      required this.cancelSearch,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
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
                      builder: (BuildContext context) => _disconnectPopup(context));
                },
                icon: Icons.power_settings_new,
              );
            } else if (widget.connectionStatus == ServerConnector.SEARCHING) {
              return StyledButton(
                onPressed: widget.cancelSearch,
                icon: Icons.cancel,
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

  Widget _disconnectPopup(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme; 

    return AlertDialog(
      alignment: Alignment.center,
      backgroundColor: colorScheme.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      // backgroundColor: ColorConstants.background,
      title: const Text(
        "Disconnect",
        style: TextStyle(
          // color: ColorConstants.darkPrimary
        )),
      actions: [
        TextButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(colorScheme.onSecondary),
          ),
          onPressed: () {
            widget.disconnect();
            Navigator.of(context).pop();
          },
          child: Text(
            "Disconnect",
            style: TextStyle(
              color: colorScheme.surface
            ),
          ),
        ),
        TextButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(colorScheme.error)
          ),
          onPressed: () {
            widget.turnOffPc();
            Navigator.of(context).pop();
          },
          child: Text(
            "Turn OFF PC",
            style: TextStyle(
              color: colorScheme.onPrimary,
            ),
          ),
        )
      ],
    );
  }
}
