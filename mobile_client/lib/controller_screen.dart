import 'package:flutter/material.dart';
import 'package:mobile_client/client/dto/input.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/color_constants.dart';
import 'package:mobile_client/connection_header.dart';
import 'package:mobile_client/mousepad.dart';
import 'package:mobile_client/buttons/styled_button.dart';
import 'package:mobile_client/shortcuts/shortcuts_sheet.dart';

import 'command_btns.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  late Future<bool> connected;

  bool showShortcutsScrollableSheet = false;

  String connectionStatus = ServerConnector.NOT_CONNECTED;

  void setConnectionState(String state) {
    setState(() => connectionStatus = state);
  }

  String getConnectionState() {
    return connectionStatus;
  }

  @override
  void initState() {
    super.initState();
    ServerConnector.init(setConnectionState, getConnectionState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        toolbarHeight: 0,
      ),
      body: Center(
        child: Stack(
          children: [
            // MAIN PAGE
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 24, vertical: 24),
              alignment: Alignment.topCenter,
              constraints: const BoxConstraints(maxWidth: 800),
              child: Stack(
                children: [
                  Column(
                    children: [
                      ConnectionHeader(
                        connectionStatus: connectionStatus,
                        connect: _connect,
                        cancelSearch: _cancelSearch,
                        disconnect: _disconnect,
                        turnOffPc: _turnOffPc,
                      ),
                      const SizedBox(
                        height: 23,
                      ),
                      // PAGE BODY
                      () { // NOT CONNECTED
                        if (connectionStatus == ServerConnector.NOT_CONNECTED) {
                          return Expanded(
                            child: Center(
                                child:
                                    Image.asset("assets/images/NoConnection.png")),
                          );
                        } else {
                          return Expanded(
                            child: Center(
                              child: FutureBuilder(
                                  future: connected,
                                  builder: (context, snapshot) {
                                    // WAITING FOR CONNECTION
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator
                                          .adaptive(
                                            backgroundColor: ColorConstants.darkPrimary,
                                          );
                                    }
                                    if (snapshot.hasError) {
                                      return Text(snapshot.error.toString());
                                    }
                                    // CONNECTED
                                    return Column(
                                      children: [
                                        MousePad(
                                          fullscreen: false,
                                        ),
                                        const SizedBox(height: 15),
                                        CommandBtns(
                                          onShowShortcutsSheet: () {
                                            setState(() {
                                              showShortcutsScrollableSheet = true;
                                            });
                                          }
                                        ),
                                      ],
                                    );
                                  }),
                            ),
                          );
                        }
                      }()
                      // BODY
                    ],
                  ),
                ],
              ),
            ),
            // SCROLABLE SHORTCUTS
            Visibility(
              visible: showShortcutsScrollableSheet,
              child: Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: ShortcutsSheet(
                  isVisible: showShortcutsScrollableSheet,
                  closeScrollableSheets: () {
                    setState(() {
                      showShortcutsScrollableSheet = false;
                      print("Scrollable sheet is now closed");
                    });
                  },
                  
                ),
              )
            ),
          ],
        ),
      ),
    );
  }

  void _connect() {
    setState(() {
      connected = ServerConnector.findServer();
    });
  }

  void _cancelSearch() {
    setState(() {
      setConnectionState(ServerConnector.NOT_CONNECTED);
    });
  }

  void _disconnect() {
    ServerConnector.sendInput(Input.disconnect());
    setState(() {
      ServerConnector.disconnect();
    });
  }

  void _turnOffPc() {
    setState(() {
      ServerConnector.sendInput(Input.shutdown());
      setState(() {
        ServerConnector.disconnect();
      });
    });
  }
}
