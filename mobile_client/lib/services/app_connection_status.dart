enum AppConnectionStatus {
  notConnected,
  searching,
  connected;

  String get label => switch (this) {
        AppConnectionStatus.notConnected => 'NOT CONNECTED',
        AppConnectionStatus.searching => 'SEARCHING...',
        AppConnectionStatus.connected => 'CONNECTED',
      };
}
