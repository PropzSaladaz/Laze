// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// part 'shortcut.g.dart';

class Shortcut {
    final String _id;
    final IconData icon;
    final String name;
    final Map<String, String> commands;

    Shortcut({
      required this.icon,
      required this.name,
      required this.commands,
    }) : _id = const Uuid().v4();

    Shortcut.withId({
      required String id,
      required this.icon,
      required this.name,
      required this.commands,
    }) : _id = id;

    String get id => _id;
}