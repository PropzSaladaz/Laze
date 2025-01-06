import 'package:flutter/material.dart';
import 'package:mobile_client/data/repositories/shortcut/shortcut_repository.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';
import 'package:mobile_client/utils/async_command.dart';
import 'package:mobile_client/utils/result.dart';

class AddCustomShortcutViewModel extends ChangeNotifier {
  final ShortcutsRepository _shortcutsRepository;

  late final AsyncCommand1<void, Shortcut> saveShortcut;


  AddCustomShortcutViewModel({
    required ShortcutsRepository shortcutsRepository
  }) : _shortcutsRepository = shortcutsRepository {
    saveShortcut = AsyncCommand1(_saveShortcut);
  }

  Future<Result<void>> _saveShortcut(Shortcut shortcut) async {
    final result = await _shortcutsRepository.saveShortcut(shortcut);
    
    if (result is Error) {
      print("Error retrieving shortcuts");
      return result;
    }

    notifyListeners();
    return result;
  }

}