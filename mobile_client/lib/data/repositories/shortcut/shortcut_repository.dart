
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';
import 'package:mobile_client/utils/result.dart';

abstract class ShortcutsRepository {
  Future<Result<void>> init();

  Future<Result<List<Shortcut>>> getShortcuts();

  Future<Result<void>> saveShortcut(Shortcut shortcut);

  Future<Result<void>> deleteShortcut(Shortcut shortcut);
}

