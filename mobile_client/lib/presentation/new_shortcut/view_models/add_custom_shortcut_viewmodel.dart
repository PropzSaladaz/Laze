import 'package:flutter/material.dart';
import 'package:mobile_client/data/repositories/shortcut/shortcut_repository.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';
import 'package:mobile_client/presentation/home/view_models/home_viewmodel.dart';
import 'package:mobile_client/utils/async_command.dart';
import 'package:mobile_client/utils/result.dart';

class AddCustomShortcutViewModel extends ChangeNotifier {
  late final AsyncCommand0 createNewShortcut;
  late final AsyncCommand0 updateShortcut;

  final HomeViewModel homeViewModel;
  
  String _id = "";
  IconData _icon = Icons.abc;
  String _name = "";
  Map<String, String> _commands = {};

  bool _isNew = true;

  AddCustomShortcutViewModel({
    required this.homeViewModel
  }) {
    createNewShortcut = AsyncCommand0(_createNewShortcut);
    updateShortcut = AsyncCommand0(_updateShortcut);
  }

  void loadFromShortcut(Shortcut shortcut) {
    _id = shortcut.id;
    _icon = shortcut.icon;
    _name = shortcut.name;
    _commands = shortcut.commands;
    _isNew = false;
  }

  void setIcon(IconData icon) {
    _icon = icon;
    notifyListeners();
  }

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void setCommand(String os, String command) {
    _commands[os] = command;
    notifyListeners();
  }

  Future<Result<void>> _createNewShortcut() async {
    bool inplaceSaving = false;
    Shortcut shortcut = Shortcut.withId(
      id: _id, 
      icon: _icon, 
      name: _name, 
      commands: _commands
    );
    await homeViewModel.saveShortcut.execute(shortcut, inplaceSaving);
    notifyListeners();
    return const Ok(null);
  }

  Future<Result<void>> _updateShortcut() async {
    bool inplaceSaving = false;
    Shortcut shortcut = Shortcut(
      icon: _icon, 
      name: _name, 
      commands: _commands
    );
    await homeViewModel.saveShortcut.execute(shortcut, inplaceSaving);
    notifyListeners();
    return const Ok(null);
  }


}