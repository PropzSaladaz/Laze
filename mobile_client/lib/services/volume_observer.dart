import 'dart:async';

import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:laze/services/gated_command_queue.dart';

/// Direction of a hardware volume button press.
enum VolumeDirection { up, down }

/// Listens for hardware volume button presses and pushes [VolumeDirection]
/// events into a [GatedCommandQueue].
///
/// Events are throttled: if two events arrive within [_minGapMs] milliseconds
/// of each other the second one is dropped. The very first volume reading on
/// startup (emitted by [FlutterVolumeController] to set the initial baseline)
/// is also silently ignored — it carries no directional information.
class VolumeObserver {
  final GatedCommandQueue<VolumeDirection> _queue;

  double? _lastVol;
  DateTime _lastEventTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _minGapMs = 100;

  StreamSubscription<double>? _sub;

  VolumeObserver(this._queue);

  /// Start listening for volume changes.
  void start() {
    _sub = FlutterVolumeController.addListener(
      (double volume) {
        // Throttle
        final now = DateTime.now();
        final gapMs = now.difference(_lastEventTime).inMilliseconds;
        if (gapMs < _minGapMs) return;
        _lastEventTime = now;

        // Direction detection
        final last = _lastVol;
        _lastVol = volume;

        // Ignore the first reading (startup baseline) and no-change events.
        if (last == null || volume == last) return;

        _queue.push(volume < last ? VolumeDirection.down : VolumeDirection.up);
      },
      emitOnStart: true,
    );
  }

  /// Stop listening. Safe to call multiple times.
  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
