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
  late final AsyncCommand deleteShortcut;

  List<Shortcut> get shortcuts => _shortcuts;

  HomeViewModel({required ShortcutsRepository shortcutsRepository})
      : _shortcutsRepository = shortcutsRepository {
    loadShortcuts = AsyncCommand0(_loadShortcuts)..execute();
    deleteShortcut = AsyncCommand1(_deleteShortcut);
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
}
