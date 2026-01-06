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

  // TODO(remote): Implement remote repository initialization for cloud sync
  // This would configure a remote backend (e.g., Firebase, custom API) for
  // cross-device shortcut synchronization.
  static void initializeRemote() async {
    throw UnimplementedError('Remote repository not yet implemented');
  }

  // Used to get all the providers
  List<SingleChildWidget> get providers {
    return [
      Provider<ShortcutsRepository>.value(
        value: shortcutsRepository,
      ),
    ];
  }
}
