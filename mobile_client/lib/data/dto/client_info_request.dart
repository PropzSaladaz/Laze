import 'package:json_annotation/json_annotation.dart';

part 'client_info_request.g.dart';

/// Data sent by client to server after connecting to dedicated port
/// Contains information about the client device
@JsonSerializable()
class ClientInfoRequest {
  @JsonKey(name: 'device_name')
  final String deviceName;

  ClientInfoRequest({
    required this.deviceName,
  });

  factory ClientInfoRequest.fromJson(Map<String, dynamic> json) =>
      _$ClientInfoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClientInfoRequestToJson(this);
}
