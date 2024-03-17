import 'package:json_annotation/json_annotation.dart';

part 'input.g.dart';

@JsonSerializable()
class Input {
  final int move_x;
  final int move_y;
  final int? button;

  Input({required this.move_x, required this.move_y, this.button});

  factory Input.leftCick() {
    return Input(move_x: 0, move_y: 0, button: 272);
  }

  factory Input.fromJson(Map<String, dynamic> json) => _$InputFromJson(json);

  Map<String, dynamic> toJson() => _$InputToJson(this);
}
