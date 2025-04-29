// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:mobile_client/core/os_config.dart';
import 'package:hive/hive.dart';

part 'shortcut_data.g.dart';

// Every Hive type a unique Id so that hive knows how to serialize/deserialize (serde)
@HiveType(typeId: 0)
class ShortcutData {

    static const int TERMINAL_COMMAND_MAX_SIZE = 256;

    // Icon data needed for serialization in Hive
    @HiveField(1)
    final String? iconFontFamily;
    @HiveField(2)
    final int iconCodePoint;
    
    // shortcut name
    @HiveField(3)
    final String name;

    // Variation of the command for each supported OS
    // Windows - commandWindows
    // Linux - commandLinux
    // ...
    @HiveField(4)
    final Map<String, String> commands;

    ShortcutData({
      required this.name,
      required this.commands,
      required this.iconCodePoint,
      required this.iconFontFamily
    });

    ShortcutData.empty():
      iconCodePoint = Icons.abc.codePoint,
      iconFontFamily = null,
      name = "",
      commands = Map.fromEntries(
        SUPPORTED_OSES.map((os) => MapEntry(os.name, ""))
      );

}