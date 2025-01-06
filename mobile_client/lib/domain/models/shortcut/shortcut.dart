// ignore_for_file: constant_identifier_names

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mobile_client/services/server_connector.dart';
import 'package:hive/hive.dart';

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