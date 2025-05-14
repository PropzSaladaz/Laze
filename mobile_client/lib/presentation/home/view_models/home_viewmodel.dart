import 'package:logging/logging.dart';

import 'package:flutter/material.dart';
import 'package:mobile_client/data/repositories/shortcut/shortcut_repository.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';
import 'package:mobile_client/utils/async_command.dart';
import 'package:mobile_client/utils/result.dart';

class HomeViewModel extends ChangeNotifier {
  final ShortcutsRepository _shortcutsRepository;
  List<Shortcut> _shortcuts = List<Shortcut>.empty(growable: true);

  final _log = Logger('HomeViewModel');
  late final AsyncCommand loadShortcuts;
  late final AsyncCommand1<void, Shortcut> deleteShortcut;
  late final AsyncCommand2<void, Shortcut, bool> saveShortcut;

  List<Shortcut> get shortcuts => _shortcuts;

  HomeViewModel({required ShortcutsRepository shortcutsRepository})
      : _shortcutsRepository = shortcutsRepository {
    loadShortcuts = AsyncCommand0(_loadShortcuts)..execute();
    deleteShortcut = AsyncCommand1(_deleteShortcut);
    saveShortcut = AsyncCommand2(_saveShortcut);
  }

  Future<Result<void>> _loadShortcuts() async {
    final result = await _shortcutsRepository.getShortcuts();

    if (result is Error) {
      _log.warning("Error retrieving shortcuts");
      return result;
    }

    _shortcuts = result.asOk.value;

    // notify data change
    notifyListeners();
    return result;
  }

  Future<Result<void>> _deleteShortcut(Shortcut shortcut) async {
    final result = await _shortcutsRepository.deleteShortcut(shortcut);

    if (result is Error) {
      _log.warning("Error deleting shortcut");
      return result;
    }

    _shortcuts.removeWhere((stc) => stc.name == shortcut.name);
    notifyListeners();
    return result;
  }

  Future<Result<void>> _saveShortcut(Shortcut shortcut, bool inplace) async {
    print("Adding new shortcut - INplace: $inplace,     shortcut: ${shortcut.id}");
    final index = _shortcuts.indexWhere((s) {
      print("Running shortcut: ${s.id}");
      return s.id == shortcut.id;
    
    });

    // shortcut already exists!
    if (index != -1) {
      if (inplace) {
        _shortcuts[index] = shortcut;
      } else {
        return Result.error(Exception("Shortcut already exists"));
      }
    }

    // new shortcut
    else {
      _shortcuts.add(shortcut);
    }

    final result = await _shortcutsRepository.saveShortcut(shortcut);
    if (result is Error) {
      _log.warning("Error saving shortcut");
    }

    notifyListeners();
    return result;
  }
}
