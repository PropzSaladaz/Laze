// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_client/client/keybinds.dart';

const int NO_CHANGE = 0;
const int RELEASE = 1;
const int HOLD = 2;

const int NO_KEY_PRESSED = -1;

const int CONNECTED = 0;
const int DISCONNECT = 1;

/// Input actions are encoded in byte arrays
/// [0u8, 1u8, ...]
/// Where the 1st byte identifies the action type at the server side,
/// while the following bytes specify the data for that action.
/// 
/// 
/// 
/// Scroll:    [2, scroll_amount]
/// MouseMove: [3, move-x, move_y]
/// 
class Input {

  // ------ KeyPress:  [0, key] -------
  static keyPress({required int key}) {
    return Uint8List.fromList([0, key]);
  }

  static keyboardBackSpace() {
    return Uint8List.fromList([0, 0]);
  }

  static mute() {
    return Uint8List.fromList([0, 1]);
  }

  static volumeDown() {
    return Uint8List.fromList([0, 2]);
  }

  static volumeUp() {
    return Uint8List.fromList([0, 3]);
  }

  static pause() {
    return Uint8List.fromList([0, 4]);
  }

  static keyboardEnter() {
    return Uint8List.fromList([0, 5]);
  }

  static brightnessDown() {
    return Uint8List.fromList([0, 10]); // unsuported yet
  }

  // ------ Text: [1, char] -------
  static keyboardCharacter({required String text}) {
    return Uint8List.fromList([1, text.codeUnitAt(0)]);
  }

 // ------ Scroll: [2, scroll_amount] -------
  static scroll({required int amount}) {
    return Uint8List.fromList([2, amount]);
  }

 // ------ MouseMove: [3, move_x, move_y] -------
  static mouseMove({required int move_x, required int move_y}) {
    return Uint8List.fromList([3, move_x, move_y]);
  }

  // ------ MouseBtn: [4, button] -------
  static leftClick() {
    return Uint8List.fromList([4, 0]);
  }

  // ------ SenseDown: [5] -------
  static sensitivityDown() {
    return Uint8List.fromList([5]);
  }

  // ------ SenseUp: [6] -------
  static sensitivityUp() {
    return Uint8List.fromList([6]);
  }

  // ------ Disconnect: [7] -------
  static disconnect() {
    return Uint8List.fromList([7]);
  }

  // static setHold() {
  //   return Input(action: 'SetHold', data: null);
  // }

  // static setRelease() {
  //   return Input(action: 'SetRelease', data: null);
  // }


}