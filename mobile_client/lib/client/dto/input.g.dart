// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Input _$InputFromJson(Map<String, dynamic> json) => Input(
      move_x: json['move_x'] as int,
      move_y: json['move_y'] as int,
      wheel_delta: json['wheel_delta'] as int,
      button: json['button'] as int,
      key_press_status: json['key_press_status'] as int,
      sensitivity_delta: json['sensitivity_delta'] as int,
      con_status: json['con_status'] as int,
    );

Map<String, dynamic> _$InputToJson(Input instance) => <String, dynamic>{
      'move_x': instance.move_x,
      'move_y': instance.move_y,
      'wheel_delta': instance.wheel_delta,
      'button': instance.button,
      'key_press_status': instance.key_press_status,
      'sensitivity_delta': instance.sensitivity_delta,
      'con_status': instance.con_status,
    };
