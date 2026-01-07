import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

/// Repository for caching server IPs for faster reconnection
class ServerCacheRepository {
  static const String boxName = 'server_cache';
  static const String lastServerKey = 'last_server';
  static const int maxCachedServers = 5;

  static final Logger _log = Logger('ServerCacheRepository');
  
  late Box<Map> _box;
  bool _initialized = false;

  /// Initialize the repository
  Future<void> init() async {
    if (_initialized) return;
    
    _box = await Hive.openBox<Map>(boxName);
    _initialized = true;
    _log.info('Server cache initialized');
  }

  /// Get the last successful server connection
  CachedServer? getLastServer() {
    if (!_initialized) return null;
    
    final data = _box.get(lastServerKey);
    if (data == null) return null;
    
    try {
      return CachedServer.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      _log.warning('Failed to parse cached server: $e');
      return null;
    }
  }

  /// Get all cached servers, ordered by most recent first
  List<CachedServer> getCachedServers() {
    if (!_initialized) return [];
    
    final servers = <CachedServer>[];
    for (int i = 0; i < maxCachedServers; i++) {
      final data = _box.get('server_$i');
      if (data != null) {
        try {
          servers.add(CachedServer.fromMap(Map<String, dynamic>.from(data)));
        } catch (e) {
          _log.warning('Failed to parse cached server $i: $e');
        }
      }
    }
    
    // Sort by most recent
    servers.sort((a, b) => b.lastConnected.compareTo(a.lastConnected));
    return servers;
  }

  /// Cache a successful server connection
  Future<void> cacheServer(String ip, int port) async {
    if (!_initialized) return;
    
    final server = CachedServer(
      ip: ip,
      port: port,
      lastConnected: DateTime.now(),
    );
    
    // Always update last server
    await _box.put(lastServerKey, server.toMap());
    
    // Add to rotating cache (avoid duplicates)
    final existing = getCachedServers();
    existing.removeWhere((s) => s.ip == ip && s.port == port);
    existing.insert(0, server);
    
    // Save up to maxCachedServers
    for (int i = 0; i < maxCachedServers && i < existing.length; i++) {
      await _box.put('server_$i', existing[i].toMap());
    }
    
    _log.info('Cached server: $ip:$port');
  }

  /// Clear all cached servers
  Future<void> clear() async {
    if (!_initialized) return;
    await _box.clear();
    _log.info('Server cache cleared');
  }
}

/// Cached server data
class CachedServer {
  final String ip;
  final int port;
  final DateTime lastConnected;

  CachedServer({
    required this.ip,
    required this.port,
    required this.lastConnected,
  });

  Map<String, dynamic> toMap() => {
    'ip': ip,
    'port': port,
    'lastConnected': lastConnected.toIso8601String(),
  };

  factory CachedServer.fromMap(Map<String, dynamic> map) => CachedServer(
    ip: map['ip'] as String,
    port: map['port'] as int,
    lastConnected: DateTime.parse(map['lastConnected'] as String),
  );

  @override
  String toString() => 'CachedServer($ip:$port, $lastConnected)';
}
