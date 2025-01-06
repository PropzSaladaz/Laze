import 'package:flutter/material.dart';
import 'package:mobile_client/data/repositories/shortcut/models/shortcut_data.dart';
import 'package:mobile_client/domain/models/shortcut/shortcut.dart';

class ShortcutsMapper {
  static Shortcut fromData(ShortcutData data) {
    return Shortcut(
      icon: IconData(
        data.iconCodePoint,
        fontFamily: data.iconFontFamily
      ),
      name: data.name,
      commands: data.commands
    );
  }

  static ShortcutData toData(Shortcut shortcut) {
    return ShortcutData(
      name: shortcut.name,
      commands: shortcut.commands,
      iconCodePoint: shortcut.icon.codePoint,
      iconFontFamily: shortcut.icon.fontFamily
    );
  }
}