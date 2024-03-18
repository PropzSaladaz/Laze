import 'package:json_annotation/json_annotation.dart';

part 'input.g.dart';

const int NO_CHANGE = 0;
const int RELEASE = 1;
const int HOLD = 2;

const int NO_KEY_PRESSED = -1;

@JsonSerializable()
class Input {
  final int move_x;
  final int move_y;
  final int button;
  final int key_press_status;
  final int sensitivity_delta;

  Input(
      {required this.move_x,
      required this.move_y,
      required this.button,
      required this.key_press_status,
      required this.sensitivity_delta});

  Input.mouseMove({move_x, move_y})
      : this(
            move_x: move_x,
            move_y: move_y,
            button: NO_KEY_PRESSED,
            key_press_status: NO_CHANGE,
            sensitivity_delta: NO_CHANGE);

  Input.leftClick()
      : this(
            move_x: NO_CHANGE,
            move_y: NO_CHANGE,
            button: 272,
            key_press_status: NO_CHANGE,
            sensitivity_delta: NO_CHANGE);

  Input.setHold()
      : this(
            move_x: NO_CHANGE,
            move_y: NO_CHANGE,
            button: NO_KEY_PRESSED,
            key_press_status: HOLD,
            sensitivity_delta: NO_CHANGE);

  Input.setRelease()
      : this(
            move_x: NO_CHANGE,
            move_y: NO_CHANGE,
            button: NO_KEY_PRESSED,
            key_press_status: RELEASE,
            sensitivity_delta: NO_CHANGE);

  Input.changeSensitivity({sensitivity})
      : this(
            move_x: NO_CHANGE,
            move_y: NO_CHANGE,
            button: NO_KEY_PRESSED,
            key_press_status: RELEASE,
            sensitivity_delta: sensitivity);

  factory Input.fromJson(Map<String, dynamic> json) => _$InputFromJson(json);

  Map<String, dynamic> toJson() => _$InputToJson(this);
}
