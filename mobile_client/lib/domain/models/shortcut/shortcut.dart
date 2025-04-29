// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

// part 'shortcut.g.dart';

class Shortcut {

    final IconData icon;
    final String name;
    final Map<String, String> commands;

    Shortcut({
      required this.icon,
      required this.name,
      required this.commands,
    });
}