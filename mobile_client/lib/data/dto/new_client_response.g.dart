// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_client_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewClientResponse _$NewClientResponseFromJson(Map<String, dynamic> json) =>
    NewClientResponse(
      port: (json['port'] as num).toInt(),
      server_os: json['server_os'] as String,
      udp_port: (json['udp_port'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NewClientResponseToJson(NewClientResponse instance) =>
    <String, dynamic>{
      'port': instance.port,
      'server_os': instance.server_os,
      'udp_port': instance.udp_port,
    };
