import 'dart:io';
import 'dart:math';

class DeviceClient {
  DeviceClient() {}

  bool tryConnect() {
    int base_ip = _ipToInt("192.168.1.0");
    var subnet_mask = 24;
    var total_local_ip_suffixes = pow(2, 32 - subnet_mask);
    for (int i = 0; i < total_local_ip_suffixes; i++) {
      var test_ip = _intToIp(base_ip | i);
    }
    return true;
  }

  int _ipToInt(String address) {
    var parts = address.split('.').map(int.parse).toList();
    return (parts[0] << 24) + (parts[1] << 16) + (parts[2] << 8) + (parts[3]);
  }

  InternetAddress _intToIp(int ip) {
    return InternetAddress([
      ip >> 24,
      (ip >> 16) & 0xFF,
      (ip >> 8) & 0xFF,
      ip & 0xFF,
    ].join("."));
  }
}
