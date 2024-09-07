// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mobile_client/client/keybinds.dart';

part 'input.g.dart';

const int NO_CHANGE = 0;
const int RELEASE = 1;
const int HOLD = 2;

const int NO_KEY_PRESSED = -1;

const int CONNECTED = 0;
const int DISCONNECT = 1;

@JsonSerializable()
class Input {

  @JsonKey(name: 'action')
  final String action;

  @JsonKey(name: 'data')
  final dynamic data;

  Input({
    required this.action, 
    required this.data
  });

  factory Input.fromJson(Map<String, dynamic> json) => _$InputFromJson(json);
  Map<String, dynamic> toJson() => _$InputToJson(this);

  // Factory constructors for different actions
  factory Input.mouseMove({required int move_x, required int move_y}) {
    return Input(action: 'MouseMove', data: {'x': move_x, 'y': move_y});
  }

  factory Input.leftClick() {
    return Input(action: 'MouseButton', data: "Left");
  }

  factory Input.setHold() {
    return Input(action: 'SetHold', data: null);
  }

  factory Input.setRelease() {
    return Input(action: 'SetRelease', data: null);
  }

  factory Input.sensitivityUp() {
    return Input(action: 'SensitivityUp', data: null);
  }

  factory Input.sensitivityDown() {
    return Input(action: 'SensitivityDown', data: null);
  }

  factory Input.volumeUp() {
    return Input(action: 'KeyPress', data: "VolumeUp");
  }

  factory Input.volumeDown() {
    return Input(action: 'KeyPress', data: "VolumeDown");
  }

  factory Input.mute() {
    return Input(action: 'KeyPress', data: "Mute");
  }

  factory Input.brightnessDown() {
    return Input(action: 'KeyPress', data: "BrightnessDown");
  }

  factory Input.pause() {
    return Input(action: 'KeyPress', data: "Pause");
  }

  factory Input.scroll({required int amount}) {
    return Input(action: 'Scroll', data: amount);
  }

  factory Input.keyPress({required int key}) {
    return Input(action: 'KeyPress', data: key);
  }

  factory Input.disconnect() {
    return Input(action: 'Disconnect', data: null);
  }

  factory Input.keyboardCharacter({required String text}) {
    return Input(action: 'Text', data: text);
  }

  factory Input.keyboardBackSpace() {
    return Input(action: 'KeyPress', data: "Backspace");
  }
}