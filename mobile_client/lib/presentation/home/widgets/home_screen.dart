import 'package:flutter/material.dart';
import 'package:mobile_client/data/services/input.dart';
import 'package:mobile_client/presentation/home/view_models/home_viewmodel.dart';
import 'package:mobile_client/services/server_connector.dart';
import 'package:mobile_client/presentation/home/widgets/connection_header.dart';
import 'package:mobile_client/presentation/core/ui/controller_page.dart';
import 'package:mobile_client/presentation/home/widgets/mousepad.dart';
import 'package:mobile_client/presentation/home/widgets/shortcuts_sheet.dart';

import 'command_btns.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<bool> connected;

  bool showShortcutsScrollableSheet = false;

  String connectionStatus = ServerConnector.NOT_CONNECTED;

  void _setConnectionState(String state) {
    setState(() => connectionStatus = state);
  }

  String _getConnectionState() {
    return connectionStatus;
  }

  @override
  void initState() {
    super.initState();
    ServerConnector.init(_setConnectionState, _getConnectionState);
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
          () {
            // NOT CONNECTED
            if (connectionStatus == ServerConnector.NOT_CONNECTED) {
              return Expanded(
                child: Center(
                    child: Image.asset("assets/images/NoConnection.png")),
              );

              // CONNECTED
            } else {
              return Expanded(
                child: Center(
                  child: FutureBuilder(
                      future: connected,
                      builder: (context, snapshot) {
                        // WAITING FOR CONNECTION
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator.adaptive(
                              backgroundColor:
                                  Theme.of(context).colorScheme.onPrimary);
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
                            CommandBtns(onShowShortcutsSheet: () {
                              setState(() {
                                showShortcutsScrollableSheet = true;
                              });
                            }),
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
              )),
    );
  }

  void _connect() {
    setState(() {
      connected = ServerConnector.findServer();
    });
  }

  void _cancelSearch() {
    setState(() {
      _setConnectionState(ServerConnector.NOT_CONNECTED);
    });
  }

  void _disconnect() {
    ServerConnector.sendInput(Input.disconnect());
    setState(() {
      ServerConnector.disconnect();
    });
  }

  void _turnOffPc() {
    ServerConnector.sendInput(Input.shutdown());

    setState(() {
      ServerConnector.disconnect();
    });
  }
}
