// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// part 'shortcut.g.dart';

class Shortcut {
    static const int maxNameLength = 18;

    final String _id;
    final IconData icon;
    final String name;
    final Map<String, String> commands;

    Shortcut({
      required this.icon,
      required String name,
      required this.commands,
    })  : name = normalizeName(name),
          _id = const Uuid().v4();

    Shortcut.withId({
      required String id,
      required this.icon,
      required String name,
      required this.commands,
    })  : name = normalizeName(name),
          _id = id;

    String get id => _id;

    static String normalizeName(String value) {
      return value.characters.take(maxNameLength).toString();
    }
}
