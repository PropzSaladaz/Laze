// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shortcut.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShortcutAdapter extends TypeAdapter<Shortcut> {
  @override
  final int typeId = 0;

  @override
  Shortcut read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Shortcut(
      name: fields[3] as String,
      commands: (fields[4] as Map).cast<String, String>(),
    )
      ..iconFontFamily = fields[1] as String?
      ..iconCodePoint = fields[2] as int;
  }

  @override
  void write(BinaryWriter writer, Shortcut obj) {
    writer
      ..writeByte(4)
      ..writeByte(1)
      ..write(obj.iconFontFamily)
      ..writeByte(2)
      ..write(obj.iconCodePoint)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.commands);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortcutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
