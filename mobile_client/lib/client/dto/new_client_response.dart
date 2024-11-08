// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'new_client_response.g.dart';

@JsonSerializable()
class NewClientResponse {
  final int port;
  final String server_os;

  NewClientResponse({
    required this.port,
    required this.server_os,  
  });

  factory NewClientResponse.fromJson(Map<String, dynamic> json) =>
      _$NewClientResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NewClientResponseToJson(this);
}
