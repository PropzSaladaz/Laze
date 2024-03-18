// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Input _$InputFromJson(Map<String, dynamic> json) => Input(
      move_x: json['move_x'] as int,
      move_y: json['move_y'] as int,
      button: json['button'] as int,
      key_press_status: json['key_press_status'] as int,
      sensitivity_delta: json['sensitivity_delta'] as int,
    );

Map<String, dynamic> _$InputToJson(Input instance) => <String, dynamic>{
      'move_x': instance.move_x,
      'move_y': instance.move_y,
      'button': instance.button,
      'key_press_status': instance.key_press_status,
      'sensitivity_delta': instance.sensitivity_delta,
    };
