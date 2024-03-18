import 'package:flutter/material.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/color_constants.dart';
import 'package:mobile_client/mousepad.dart';
import 'package:mobile_client/buttons/styled_button.dart';

import 'command_btns.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  late ServerConnector connector;
  late Future<bool> connected;

  String connectionStatus = ServerConnector.NOT_CONNECTED;

  void setConnectionState(String state) {
    setState(() => connectionStatus = state);
  }

  @override
  void initState() {
    super.initState();
    connector = ServerConnector(setConnectionStatus: setConnectionState);
  }

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
              // CONNECTION HEADER
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
                    () {
                      // CONNECTED -> button used to disconnect
                      if (connectionStatus == ServerConnector.CONNECTED) {
                        return StyledButton(
                          onPressed: () {
                            setState(() {
                              connector.disconnect();
                            });
                          },
                          icon: Icons.power_settings_new,
                        );
                      } else {
                        // NOT CONNECTED -> button used to connect
                        return StyledButton(
                          onPressed: () {
                            setState(() {
                              connected = connector.findServer();
                            });
                          },
                          icon: Icons.screen_search_desktop_outlined,
                        );
                      }
                    }()
                  ],
                ),
              ),
              const SizedBox(
                height: 23,
              ),
              () {
                if (connectionStatus == ServerConnector.NOT_CONNECTED) {
                  return Text("not connected");
                } else {
                  return FutureBuilder(
                      future: connected,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
                        }
                        if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }

                        return Column(
                          children: [
                            MousePad(
                              connector: connector,
                            ),
                            CommandBtns(
                              connector: connector,
                            ),
                          ],
                        );
                      });
                }
              }()
              // BODY
            ],
          ),
        ),
      ),
    );
  }
}
