
import 'package:laze/domain/models/shortcut/shortcut.dart';
import 'package:laze/utils/result.dart';

abstract class ShortcutsRepository {
  Future<Result<void>> init();

  Future<Result<List<Shortcut>>> getShortcuts();

  Future<Result<void>> saveShortcut(Shortcut shortcut);

  Future<Result<void>> deleteShortcut(Shortcut shortcut);
}

