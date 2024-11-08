// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_client/client/keybinds.dart';
import 'package:mobile_client/client/server_connector.dart';
import 'package:mobile_client/shortcuts/shortcut.dart';

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
  static Uint8List keyPress({required int key}) {
    return Uint8List.fromList([0, key]);
  }

  static Uint8List keyboardBackSpace() {
    return Uint8List.fromList([0, 0]);
  }

  static Uint8List mute() {
    return Uint8List.fromList([0, 1]);
  }

  static Uint8List volumeDown() {
    return Uint8List.fromList([0, 2]);
  }

  static Uint8List volumeUp() {
    return Uint8List.fromList([0, 3]);
  }

  static Uint8List pause() {
    return Uint8List.fromList([0, 4]);
  }

  static Uint8List keyboardEnter() {
    return Uint8List.fromList([0, 5]);
  }

  static Uint8List brightnessDown() {
    return Uint8List.fromList([0, 10]); // unsuported yet
  }

  // ------ Text: [1, char] -------
  static Uint8List keyboardCharacter({required String text}) {
    return Uint8List.fromList([1, text.codeUnitAt(0)]);
  }

 // ------ Scroll: [2, scroll_amount] -------
  static Uint8List scroll({required int amount}) {
    return Uint8List.fromList([2, amount]);
  }

 // ------ MouseMove: [3, move_x, move_y] -------
  static Uint8List mouseMove({required int move_x, required int move_y}) {
    return Uint8List.fromList([3, move_x, move_y]);
  }

  // ------ MouseBtn: [4, button] -------
  static Uint8List leftClick() {
    return Uint8List.fromList([4, 0]);
  }

  // ------ SenseDown: [5] -------
  static Uint8List sensitivityDown() {
    return Uint8List.fromList([5]);
  }

  // ------ SenseUp: [6] -------
  static Uint8List sensitivityUp() {
    return Uint8List.fromList([6]);
  }

  // ------ Disconnect: [7] -------
  static Uint8List disconnect() {
    return Uint8List.fromList([7]);
  }

  // ------ Shutdown: [8] -------
  static Uint8List shutdown() {
    return Uint8List.fromList([8]);
  }

  // ------ Run Terminal Command: [9] -------
  // Command: [9, command_size, command]
  static Uint8List runCommand(Map os_commands) {
    String command = os_commands[ServerConnector.getServerOS()];

    if (command.length >= Shortcut.TERMINAL_COMMAND_MAX_SIZE) {
      // should never happen - the TextField UI itself limits command size to 256 characters
      throw const FormatException("Command length exceeds the 256-character limit");
    }
    // 9 is the command code, then we send command size (nbr of characters) followed
    // by the command for each suported OS
    List<int> encoded_commands = [9, command.length];
    List<int> commandBytes = utf8.encode(command);
    encoded_commands.addAll(commandBytes);
    return Uint8List.fromList(encoded_commands);
  }

  // static setHold() {
  //   return Input(action: 'SetHold', data: null);
  // }

  // static setRelease() {
  //   return Input(action: 'SetRelease', data: null);
  // }


}