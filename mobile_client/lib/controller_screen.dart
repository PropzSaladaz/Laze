import 'package:flutter/material.dart';
import 'package:mobile_client/client/dto/input.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/color_constants.dart';
import 'package:mobile_client/connection_header.dart';
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        toolbarHeight: 0,
      ),
      body: Center(
        child: Container(
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
                    disconnect: _disconnect,
                    turnOffPc: _turnOffPc,
                  ),
                  const SizedBox(
                    height: 23,
                  ),
                  // PAGE BODY
                  () {
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
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator
                                      .adaptive();
                                }
                                if (snapshot.hasError) {
                                  return Text(snapshot.error.toString());
                                }

                                return Column(
                                  children: [
                                    MousePad(
                                      connector: connector,
                                    ),
                                    const SizedBox(height: 15),
                                    CommandBtns(
                                      connector: connector,
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
      ),
    );
  }

  void _connect() {
    setState(() {
      setConnectionState(ServerConnector.SEARCHING);
      connected = connector.findServer();
    });
  }

  void _disconnect() {
    connector.sendInput(Input.disconnect());
    setState(() {
      connector.disconnect();
    });
  }

  void _turnOffPc() {
    setState(() {
      connector.disconnect();
    });
  }
}
