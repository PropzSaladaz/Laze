import 'package:json_annotation/json_annotation.dart';

part 'new_client_response.g.dart';

@JsonSerializable()
class NewClientResponse {
  final int port;

  NewClientResponse({required this.port});

  factory NewClientResponse.fromJson(Map<String, dynamic> json) =>
      _$NewClientResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NewClientResponseToJson(this);
}
