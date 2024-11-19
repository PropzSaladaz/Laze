
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_client/data/model/shortcut.dart';

class ShortcutsProvider extends ChangeNotifier {
  static const String _shortcutsBoxName = "shortcuts";

  Box<Shortcut>? _shortcutsBox;
  List<Shortcut> _shortcuts = [];

  bool _isLoading = true;
  String? _error;

  // getters
  UnmodifiableListView<Shortcut> get shortcuts => UnmodifiableListView(_shortcuts);
  int get length => _shortcuts.length; 

  bool get isLoading => _isLoading;
  String? get error => _error;

  // private constructor
  ShortcutsProvider();
  
  Future<void> init() async {
    try {
      _shortcutsBox = await Hive.openBox(_shortcutsBoxName);
      _shortcuts = _shortcutsBox!.values.toList();
      print("Loaded shortcuts successfully - $_shortcuts");
    } catch(e) {
      print("Error creating box using Hive");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  } 

  Future<void> addShortcut(Shortcut shortcut) async {
    try {
      await _shortcutsBox!.add(shortcut);
      _shortcuts.add(shortcut);
    } catch (e) {
      print("Error when adding shortcut");
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeShortcut(int index) async {
    try {
      await _shortcutsBox!.deleteAt(index);
      _shortcuts.removeAt(index);
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }

  }

}