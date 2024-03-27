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
  final int move_x;
  final int move_y;
  final int wheel_delta;
  final int button;
  final int key_press_status;
  final int sensitivity_delta;
  final int con_status;

  Input(
      {required this.move_x,
      required this.move_y,
      required this.wheel_delta,
      required this.button,
      required this.key_press_status,
      required this.sensitivity_delta,
      required this.con_status});

  Input.mouseMove({move_x, move_y})
      : this(
            move_x: move_x,
            move_y: move_y,
            wheel_delta: NO_CHANGE,
            button: NO_KEY_PRESSED,
            key_press_status: NO_CHANGE,
            sensitivity_delta: NO_CHANGE,
            con_status: CONNECTED);

  Input.setHold()
      : this(
            move_x: NO_CHANGE,
            move_y: NO_CHANGE,
            wheel_delta: NO_CHANGE,
            button: NO_KEY_PRESSED,
            key_press_status: HOLD,
            sensitivity_delta: NO_CHANGE,
            con_status: CONNECTED);

  Input.setRelease()
      : this(
            move_x: NO_CHANGE,
            move_y: NO_CHANGE,
            wheel_delta: NO_CHANGE,
            button: NO_KEY_PRESSED,
            key_press_status: RELEASE,
            sensitivity_delta: NO_CHANGE,
            con_status: CONNECTED);

  Input.changeSensitivity({sensitivity})
      : this(
            move_x: NO_CHANGE,
            move_y: NO_CHANGE,
            wheel_delta: NO_CHANGE,
            button: NO_KEY_PRESSED,
            key_press_status: NO_CHANGE,
            sensitivity_delta: sensitivity,
            con_status: CONNECTED);

  static Input leftClick() {
    return Input.pressKey(key: Keybinds.LEFT_CLICK);
  }

  static Input volumeUp() {
    return Input.pressKey(key: Keybinds.VOL_UP);
  }

  static Input volumeDown() {
    return Input.pressKey(key: Keybinds.VOL_DOWN);
  }

  static Input pause() {
    return Input.pressKey(key: Keybinds.PAUSE);
  }

  static Input mute() {
    return Input.pressKey(key: Keybinds.MUTE);
  }

  static Input brightnessDown() {
    return Input.pressKey(key: Keybinds.BRIGHTNESS_DOWN);
  }

  static Input disconnect() {
    return Input(
        move_x: NO_CHANGE,
        move_y: NO_CHANGE,
        wheel_delta: NO_CHANGE,
        button: NO_KEY_PRESSED,
        key_press_status: NO_CHANGE,
        sensitivity_delta: NO_CHANGE,
        con_status: DISCONNECT);
  }

  static Input pressKey({required int key}) {
    return Input(
        move_x: NO_CHANGE,
        move_y: NO_CHANGE,
        wheel_delta: NO_CHANGE,
        button: key,
        key_press_status: NO_CHANGE,
        sensitivity_delta: NO_CHANGE,
        con_status: CONNECTED);
  }

  static Input scroll({required int amount}) {
    return Input(
        move_x: NO_CHANGE,
        move_y: NO_CHANGE,
        wheel_delta: amount,
        button: NO_KEY_PRESSED,
        key_press_status: NO_CHANGE,
        sensitivity_delta: NO_CHANGE,
        con_status: CONNECTED);
  }

  factory Input.fromJson(Map<String, dynamic> json) => _$InputFromJson(json);

  Map<String, dynamic> toJson() => _$InputToJson(this);
}
