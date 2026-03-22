import 'package:flutter/services.dart';

/// Thin wrapper around [HapticFeedback] that respects the user's preference.
/// Call [HapticService.enabled] = false to silence all haptics app-wide.
abstract final class HapticService {
  static bool enabled = true;

  static void light() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }
}
