import 'package:mobile_client/data/repositories/shortcut/shortcut_repository.dart';
import 'package:mobile_client/data/repositories/shortcut/shortcuts_repository_local.dart';
import 'package:provider/single_child_widget.dart';
import 'package:provider/provider.dart';

/// Configure dependencies for local data.
/// This dependency list uses repositories that provide local data.
List<SingleChildWidget> get providersLocal {
  return [
    Provider(
      create: (context) => ShortcutsRepositoryLocal() as ShortcutsRepository,
    ),
  ];
}
