// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
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
/// Command: [9, string_size, command_bytes]
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

  // ------ Shutdown: [8] -------
  static shutdown() {
    return Uint8List.fromList([8]);
  }

  // ------ Run Terminal Command: [9] -------
  // Command: [9, string_size, command_bytes]
  static runCommand(String command) {
    int commandSize = command.length;
    // enough to fit within a single u8
    if (commandSize < 256) {
      List<int> commandBytes = utf8.encode(command);
      // 9 is the command code, then we send command size (nbr of characters), and a null byte 
      // to specify that after that we have the actual command chars
      List<int> commandMetadata = [9, commandSize];
      commandMetadata.addAll(commandBytes);
      return Uint8List.fromList(commandMetadata);
    }

  }

  // static setHold() {
  //   return Input(action: 'SetHold', data: null);
  // }

  // static setRelease() {
  //   return Input(action: 'SetRelease', data: null);
  // }


}