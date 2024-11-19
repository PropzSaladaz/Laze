// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:mobile_client/services/server_connector.dart';
import 'package:hive/hive.dart';

part 'shortcut.g.dart';

// Every Hive type a unique Id so that hive knows how to serde
@HiveType(typeId: 0)
class Shortcut {

    static const int TERMINAL_COMMAND_MAX_SIZE = 256;

    // Icon data needed for serialization in Hive
    @HiveField(1)
    String? iconFontFamily;
    @HiveField(2)
    int iconCodePoint;
    
    // shortcut name
    @HiveField(3)
    String name;

    // a map of commands - the same command for each different OS
    @HiveField(4)
    Map<String, String> commands;



    Shortcut({
      required this.name,
      required this.commands,
    }) : iconCodePoint = 0;

    Shortcut.withIcon({
      required IconData icon,
      required this.name,
      required this.commands,
    }) : 
      iconCodePoint = icon.codePoint, 
      iconFontFamily = icon.fontFamily;

    Shortcut.empty():
      iconCodePoint = Icons.abc.codePoint,
      name = "",
      commands = Map.fromEntries(
        ServerConnector.SUPPORTED_OSES.map((os) => MapEntry(os, ""))
      );

    // get the icon from codePoint + fontFamily
    IconData get icon => IconData(
      iconCodePoint,
      fontFamily: iconFontFamily
    );

}