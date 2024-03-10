import 'package:json_annotation/json_annotation.dart';

part 'input.g.dart';

@JsonSerializable()
class Input {
  final int move_x;
  final int move_y;

  Input({required this.move_x, required this.move_y});

  factory Input.fromJson(Map<String, dynamic> json) => _$InputFromJson(json);

  Map<String, dynamic> toJson() => _$InputToJson(this);
}
