import 'package:mobile_client/data/repositories/shortcut/shortcut_repository.dart';
import 'package:mobile_client/data/repositories/shortcut/shortcuts_repository_local.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class RepositoryService {
  final ShortcutsRepository shortcutsRepository;

  const RepositoryService._({required this.shortcutsRepository});

  /// Configure dependencies for local data.
  static Future<RepositoryService> initializeLocal() async {
    final ShortcutsRepository shortcutsRepoLocal =
        await ShortcutsRepositoryLocal.create();

    return RepositoryService._(shortcutsRepository: shortcutsRepoLocal);
  }

  // TODO
  static void initializeRemote() async {}

  // Used to get all the providers
  List<SingleChildWidget> get providers {
    return [
      Provider<ShortcutsRepository>.value(
        value: shortcutsRepository,
      ),
    ];
  }
}
