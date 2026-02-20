import 'dart:async';

import 'package:flutter_volume_controller/flutter_volume_controller.dart';

/// Direction of a hardware volume button press.
enum VolumeDirection { up, down }

/// Listens for hardware volume button presses and pushes [VolumeDirection]
/// events into a [Stream].
///
/// Events are throttled: if two events arrive within [_minGapMs] milliseconds
/// of each other the second one is dropped. The very first volume reading on
/// startup (emitted by [FlutterVolumeController] to set the initial baseline)
/// is also silently ignored — it carries no directional information.
class VolumeObserver {
  final _controller = StreamController<VolumeDirection>();
  Stream<VolumeDirection> get stream => _controller.stream;

  double? _lastVol;
  DateTime _lastEventTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastBounceTime = DateTime.fromMillisecondsSinceEpoch(0);

  static const int _minGapMs = 50;
  static const int _bounceIgnoreMs = 200;

  StreamSubscription<double>? _sub;

  VolumeObserver();

  /// Start listening for volume changes.
  void start() {
    _sub = FlutterVolumeController.addListener(
      (double volume) {
        print("Volume: $volume");
        final now = DateTime.now();

        // If we just bounced the volume programmatically, ignore the subsequent
        // event it triggers to avoid a false reverse "Up/Down" command.
        if (now.difference(_lastBounceTime).inMilliseconds < _bounceIgnoreMs) {
          _lastVol = volume;
          return;
        }

        // Throttle by time to debounce multi-fires
        final gapMs = now.difference(_lastEventTime).inMilliseconds;
        if (gapMs < _minGapMs) return;

        final last = _lastVol;
        _lastVol = volume;

        // Bouncing mechanism:
        // `flutter_volume_controller` uses `.distinct()` internally. If the phone's
        // hardware volume hits exactly 0.0 or 1.0, further presses of the same
        // button are discarded at the platform level and will never reach Dart.
        // To fix holding and rapid clicks, we instantly snap the volume back to the
        // dead center (0.5) any time it wanders too close to the edge.
        if (volume <= 0.3 || volume >= 0.7) {
          _lastBounceTime = now;
          FlutterVolumeController.setVolume(0.5);
        }

        // Ignore the baseline emission on start
        if (last == null) return;

        VolumeDirection direction;

        if (volume > last) {
          direction = VolumeDirection.up;
        } else if (volume < last) {
          direction = VolumeDirection.down;
        } else {
          return;
        }

        _lastEventTime = now;
        _controller.add(direction);
      },
      emitOnStart: true,
    );
  }

  /// Stop listening. Safe to call multiple times.
  void dispose() {
    _sub?.cancel();
    _sub = null;
    _controller.close();
  }
}
