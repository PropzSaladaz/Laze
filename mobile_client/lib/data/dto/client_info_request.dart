// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'client_info_request.g.dart';

/// Data sent by client to server after connecting to dedicated port
/// Contains information about the client device
@JsonSerializable()
class ClientInfoRequest {
  final String device_name;

  ClientInfoRequest({
    required this.device_name,  
  });

  factory ClientInfoRequest.fromJson(Map<String, dynamic> json) =>
      _$ClientInfoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClientInfoRequestToJson(this);
}
