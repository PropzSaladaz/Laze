// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:laze/core/limit_constants.dart';
import 'package:laze/services/server_connector.dart';

/// This class handles the encoding of any iput action into bytes.
/// These bytes are then sent to the server to be processed and executed.
///
/// Input actions are encoded in byte arrays
/// `[0u8, 1u8, ...]`
/// Where the 1st byte identifies the action type at the server side,
/// while the following bytes specify the data for that action.
///
/// - Scroll:    `[2, scroll_amount]`
/// - MouseMove: `[3, move-x, move_y]`
/// - Command: `[7, UTF-8_byte_count, command_bytes]`
/// ...
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

  static Uint8List play() {
    return Uint8List.fromList([0, 5]);
  }

  static Uint8List keyboardEnter() {
    return Uint8List.fromList([0, 6]);
  }

  static Uint8List fullScreen() {
    return Uint8List.fromList([0, 7]);
  }

  static Uint8List closeTab() {
    return Uint8List.fromList([0, 8]);
  }

  static Uint8List previousTab() {
    return Uint8List.fromList([0, 10]);
  }

  static Uint8List nextTab() {
    return Uint8List.fromList([0, 9]);
  }

  static Uint8List brightnessDown() {
    return Uint8List.fromList([0, 11]); // unsuported yet
  }

  static Uint8List altTab() {
    return Uint8List.fromList([0, 12]);
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

  static Uint8List rightClick() {
    return Uint8List.fromList([4, 1]);
  }

  // ------ Disconnect: [5] -------
  static Uint8List disconnect() {
    return Uint8List.fromList([5]);
  }

  // ------ Shutdown: [6] -------
  static Uint8List shutdown() {
    return Uint8List.fromList([6]);
  }

  // ------ Run Terminal Command: [7] -------
  // Command: [7, command_size, command]
  static Uint8List runCommand(Map os_commands) {
    String serverOS = ServerConnector.getServerOS();
    String command = os_commands[serverOS] as String? ?? '';
    final commandBytes = utf8.encode(command);

    if (commandBytes.length >= Limits.TERMINAL_COMMAND_MAX_SIZE) {
      // UTF-8 can use several bytes per character, so enforce the wire limit here.
      throw const FormatException("Command exceeds the 255-byte UTF-8 limit");
    } else if (command.isEmpty) {
      throw FormatException("No command specified for $serverOS OS");
    }
    // 7 is the command code, followed by the UTF-8 byte count and command bytes.
    List<int> encoded_commands = [7, commandBytes.length];
    encoded_commands.addAll(commandBytes);
    return Uint8List.fromList(encoded_commands);
  }

  // ------ MouseDown: [8] -------
  static Uint8List mouseDown() {
    return Uint8List.fromList([8, 0]);
  }

  // ------ MouseUp: [9] -------
  static Uint8List mouseUp() {
    return Uint8List.fromList([9, 0]);
  }

  // static setHold() {
  //   return Input(action: 'SetHold', data: null);
  // }

  // static setRelease() {
  //   return Input(action: 'SetRelease', data: null);
  // }
}
