import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:laze/data/repositories/shortcut/shortcut_repository.dart';
import 'package:laze/domain/models/shortcut/shortcut.dart';
import 'package:laze/services/volume_service.dart';
import 'package:laze/utils/async_command.dart';
import 'package:laze/utils/result.dart';
import 'package:logging/logging.dart';

class HomeViewModel extends ChangeNotifier {
  final ShortcutsRepository _shortcutsRepository;
  final VolumeService _volumeService;

  List<Shortcut> _shortcuts = List<Shortcut>.empty(growable: true);

  final _log = Logger('HomeViewModel');
  late final AsyncCommand loadShortcuts;
  late final AsyncCommand1<void, Shortcut> deleteShortcut;
  late final AsyncCommand1<void, Shortcut> saveShortcut;

  List<Shortcut> get shortcuts => _shortcuts;

  HomeViewModel({
    required ShortcutsRepository shortcutsRepository,
    required void Function(Uint8List bytes) sendInput,
  })  : _shortcutsRepository = shortcutsRepository,
        _volumeService = VolumeService() {
    loadShortcuts = AsyncCommand0(_loadShortcuts)..execute();
    deleteShortcut = AsyncCommand1(_deleteShortcut);
    saveShortcut = AsyncCommand1(_saveShortcut);

    _volumeService.start(sendInput);
  }

  // ── Volume / connection gate ───────────────────────────────────────────────

  /// Call when a server connection is successfully established.
  void onConnected() => _volumeService.setConnected();

  /// Call when the server connection is lost, cancelled, or shut down.
  void onDisconnected() => _volumeService.setDisconnected();

  // ── Shortcuts ─────────────────────────────────────────────────────────────

  Future<Result<void>> _loadShortcuts() async {
    final result = await _shortcutsRepository.getShortcuts();

    if (result is Error) {
      _log.warning("Error retrieving shortcuts");
      return result;
    }

    _shortcuts = result.asOk.value;
    notifyListeners();
    return result;
  }

  Future<Result<void>> _deleteShortcut(Shortcut shortcut) async {
    final result = await _shortcutsRepository.deleteShortcut(shortcut);

    if (result is Error) {
      _log.warning("Error deleting shortcut");
      return result;
    }

    _shortcuts.removeWhere((stc) => stc.id == shortcut.id);
    notifyListeners();
    return result;
  }

  Future<Result<void>> _saveShortcut(Shortcut shortcut) async {
    final index = _shortcuts.indexWhere((s) => s.id == shortcut.id);

    // Overwrite in case it exists
    // UUIDs should never overlap for new shortcuts
    if (index != -1) {
      _shortcuts[index] = shortcut;
    } else {
      _shortcuts.add(shortcut);
    }

    final result = await _shortcutsRepository.saveShortcut(shortcut);
    if (result is Error) {
      _log.warning("Error saving shortcut");
    }

    notifyListeners();
    return result;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _volumeService.dispose();
    super.dispose();
  }
}
