import 'package:flutter/material.dart';
import 'package:mobile_client/data/dto/input.dart';
import 'package:mobile_client/data/state/shortcuts_provider.dart';
import 'package:mobile_client/services/server_connector.dart';
import 'package:mobile_client/core/constants/color_constants.dart';
import 'package:mobile_client/presentation/components/connection_header.dart';
import 'package:mobile_client/controller_page.dart';
import 'package:mobile_client/presentation/components/mousepad.dart';
import 'package:mobile_client/presentation/pages/shortcuts/shortcuts_sheet.dart';
import 'package:provider/provider.dart';

import '../components/command_btns.dart';

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

    return ControllerPage(
      resizeToAvoidBottomInset: false,
      body: Column(
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
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive(backgroundColor: 
                            ColorConstants.darkPrimary);
                        } else if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }
                        // CONNECTED
                        return Column(
                          children: [
                            const MousePad(
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
      stackedBody:           
        // SCROLABLE SHORTCUTS
        Visibility(
          visible: showShortcutsScrollableSheet,
          child: Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            // Propagates changes to widgets in the tree
            child: ShortcutsSheet(
              isVisible: showShortcutsScrollableSheet,
              closeScrollableSheets: () {
                setState(() {
                  showShortcutsScrollableSheet = false;
                });
              },
              
            ),
          )
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
