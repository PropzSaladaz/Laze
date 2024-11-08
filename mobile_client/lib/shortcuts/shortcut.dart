// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:mobile_client/client/server_connector.dart';

class Shortcut {

  static const int TERMINAL_COMMAND_MAX_SIZE = 256;

  IconData icon;
  String name;
  // a map of commands - the same command for each different OS
  Map<String, String> commands;

  Shortcut({
    required this.icon,
    required this.name,
    required this.commands,
  });

  Shortcut.empty():
    icon = Icons.abc,
    name = "",
    commands = Map.fromEntries(
      ServerConnector.SUPPORTED_OSES.map((os) => MapEntry(os, ""))
    );

}