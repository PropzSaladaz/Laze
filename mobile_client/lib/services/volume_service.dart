import 'dart:async';
import 'dart:typed_data';

import 'package:laze/data/services/input.dart';
import 'package:laze/services/volume_observer.dart';

/// Orchestrates [VolumeObserver] into a single lifecycle-managed service.
///
/// Typical usage:
/// ```dart
/// final service = VolumeService();
/// service.start(ServerConnector.sendInput); // call once, e.g. in initState
/// service.setConnected();                   // open gate on connect
/// service.setDisconnected();                // close gate on disconnect
/// service.dispose();                        // call in dispose()
/// ```
class VolumeService {
  final VolumeObserver _observer = VolumeObserver();
  StreamSubscription<VolumeDirection>? _sub;

  bool _started = false;

  /// Wire up and start the observer.
  ///
  /// [sendInput] is called with the encoded byte payload for each volume event
  /// that passes through the gate. Typically [ServerConnector.sendInput].
  ///
  /// Call this once (e.g. in `initState`). The observer runs for the lifetime
  /// of the service; only the stream pauses/resumes with connection state.
  void start(void Function(Uint8List bytes) sendInput) {
    assert(!_started, 'VolumeService.start() called more than once');
    _started = true;

    _observer.start();

    _sub = _observer.stream.listen((VolumeDirection dir) {
      sendInput(
        dir == VolumeDirection.up ? Input.volumeUp() : Input.volumeDown(),
      );
    });

    // Start paused, waiting for connection
    _sub?.pause();
  }

  // ── Gate control ──────────────────────────────────────────────────────────

  /// Open the gate — call when the server connection is established.
  void setConnected() => _sub?.resume();

  /// Close the gate — call when the server connection is lost or cancelled.
  void setDisconnected() => _sub?.pause();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Stop the observer and consumer. Safe to call even if [start] was never
  /// called (no-op).
  void dispose() {
    if (!_started) return;
    _sub?.cancel();
    _observer.dispose();
  }
}
