// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shortcut_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShortcutDataAdapter extends TypeAdapter<ShortcutData> {
  @override
  final int typeId = 0;

  @override
  ShortcutData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShortcutData(
      id: fields[1] as String,
      name: fields[4] as String,
      commands: (fields[5] as Map).cast<String, String>(),
      iconCodePoint: fields[3] as int,
      iconFontFamily: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShortcutData obj) {
    writer
      ..writeByte(5)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.iconFontFamily)
      ..writeByte(3)
      ..write(obj.iconCodePoint)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.commands);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortcutDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
