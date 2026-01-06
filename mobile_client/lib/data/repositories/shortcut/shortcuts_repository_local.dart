import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:mobile_client/data/repositories/shortcut/models/shortcut_data.dart';
import 'package:mobile_client/data/repositories/shortcut/models/shortcuts_mapper.dart';
import 'package:mobile_client/data/repositories/shortcut/shortcut_repository.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';
import 'package:mobile_client/utils/result.dart';

class ShortcutsRepositoryLocal extends ShortcutsRepository {
  static const String _shortcutsBoxName = "shortcuts";

  static final _log = Logger("ShortcutsRepositoryLocal");

  late Box<ShortcutData> _shortcutsBox;

  // private constructor
  ShortcutsRepositoryLocal._();

  static Future<ShortcutsRepositoryLocal> create() async {
    final repo = ShortcutsRepositoryLocal._();

    _log.info("Initializing shortcuts repo");
    final result = await repo.init();

    switch (result) {
      case Ok():
        _log.info("Successfully initialized");
        return repo;
      case Error(:final Exception error):
        _log.warning(error);
        throw error;
    }
  }

  @override
  Future<Result<void>> init() async {
    try {
      _shortcutsBox = await Hive.openBox(_shortcutsBoxName);
      _log.info("Loaded shortcuts successfully");
      return const Ok(null);
    } catch (e) {
      _log.warning("Error creating box using Hive");
      return Error(Exception(e));
    }
  }

  @override
  Future<Result<List<Shortcut>>> getShortcuts() async {
    try {
      List<ShortcutData> shortcutsData = _shortcutsBox.values.toList();
      List<Shortcut> shortcuts = shortcutsData
          .map((ShortcutData data) => ShortcutsMapper.fromData(data))
          .toList();
      return Ok(shortcuts);
    } catch (e) {
      _log.warning("Error retrieving shortcuts");
      return Error(Exception(e));
    }
  }

  @override
  Future<Result<void>> saveShortcut(Shortcut shortcut) async {
    try {
      await _shortcutsBox.put(shortcut.id, ShortcutsMapper.toData(shortcut));
      return const Ok(null);
    } catch (e) {
      _log.warning("Error when saving shortcut");
      return Error(Exception(e));
    }
  }

  @override
  Future<Result<void>> deleteShortcut(Shortcut shortcut) async {
    try {
      await _shortcutsBox.delete(shortcut.id);
      return const Ok(null);
    } catch (e) {
      _log.warning("Error when deleting shortcut");
      return Error(Exception(e));
    }
  }
}
