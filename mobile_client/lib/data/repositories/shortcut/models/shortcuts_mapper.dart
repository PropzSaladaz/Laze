import 'package:flutter/material.dart';
import 'package:laze/data/repositories/shortcut/models/shortcut_data.dart';
import 'package:laze/domain/models/shortcut/shortcut.dart';

/// Transforms Shortcut data between a serialized-friendly object and a in-memory object.
/// This is needed since for the ViewModel layer we use the Shortcut object, where the Icon
/// field is allowed to be an object. Whereas in the repository layer we are not allowed
/// to have the Icon object, and need to transform it into a more serialize-friendly
/// format
class ShortcutsMapper {

  /// Converts a serialize-friendly Shortcut object into a model Shortcut object
  static Shortcut fromData(ShortcutData data) {
    return Shortcut.withId(
      id: data.id,
      icon: IconData(
        data.iconCodePoint,
        fontFamily: data.iconFontFamily
      ),
      name: data.name,
      commands: data.commands
    );
  }

  /// Converts a model Shortcut object into a serialize-friendly Shortcut object
  static ShortcutData toData(Shortcut shortcut) {
    return ShortcutData(
      id: shortcut.id,
      name: shortcut.name,
      commands: shortcut.commands,
      iconCodePoint: shortcut.icon.codePoint,
      iconFontFamily: shortcut.icon.fontFamily
    );
  }
}