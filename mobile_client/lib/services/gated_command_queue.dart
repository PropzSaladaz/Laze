import 'dart:async';
import 'dart:collection';

/// A generic producer/consumer queue whose consumer is gated by a condition.
///
/// Items pushed by producers accumulate in the queue at all times.
/// The consumer loop only drains items when the gate is open ([setReady]).
/// When the gate is closed ([unsetReady]) the consumer suspends without
/// blocking the main thread — it awaits a [Completer] future.
///
/// Usage:
/// ```dart
/// final queue = GatedCommandQueue<MyEvent>();
/// queue.consume((event) async { /* handle */ });
/// queue.setReady();   // open gate
/// queue.push(event);  // enqueue
/// queue.unsetReady(); // close gate
/// queue.dispose();    // stop consumer
/// ```
class GatedCommandQueue<T> {
  final Queue<T> _queue = Queue<T>();

  /// Gate completer — awaited by the consumer loop.
  /// Starts as an uncompleted completer (gate closed / not ready).
  Completer<void> _gate = Completer<void>();

  /// Wakes the consumer when a new item is pushed while the gate is open.
  Completer<void> _itemAvailable = Completer<void>();

  bool _running = false;
  Future<void> Function(T item)? _handler;

  // ── Gate control ──────────────────────────────────────────────────────────

  /// Open the gate. The consumer will start (or resume) draining the queue.
  void setReady() {
    if (!_gate.isCompleted) _gate.complete();
  }

  /// Close the gate. The consumer suspends after finishing the current item.
  void unsetReady() {
    if (_gate.isCompleted) _gate = Completer<void>();
  }

  // ── Producer ──────────────────────────────────────────────────────────────

  /// Enqueue [item]. If the gate is open and the consumer is waiting for
  /// items, it is woken immediately.
  void push(T item) {
    _queue.add(item);
    if (_gate.isCompleted && !_itemAvailable.isCompleted) {
      _itemAvailable.complete();
    }
  }

  // ── Consumer ──────────────────────────────────────────────────────────────

  /// Start the async consumer loop.
  ///
  /// [handler] is called for each item, one at a time, in FIFO order.
  /// The loop never blocks the main isolate — it suspends via [Future] awaits.
  /// Call [dispose] to stop it.
  void consume(Future<void> Function(T item) handler) {
    assert(!_running, 'consume() called more than once');
    _handler = handler;
    _running = true;
    _runLoop();
  }

  void _runLoop() {
    if (!_running) return;

    Future(() async {
      // 1. Wait until the gate is open.
      await _gate.future;

      if (!_running) return;

      // 2. Process all currently queued items.
      while (_queue.isNotEmpty && _running) {
        // Re-check gate each iteration — unsetReady() may have been called.
        if (!_gate.isCompleted) break;
        final item = _queue.removeFirst();
        await _handler!(item);
      }

      if (!_running) return;

      // 3. If queue is empty and gate is still open, wait for the next push.
      if (_queue.isEmpty && _gate.isCompleted) {
        _itemAvailable = Completer<void>();
        await _itemAvailable.future;
      }

      // 4. Schedule next iteration as a new microtask-free Future so we
      //    never starve the event loop.
      _runLoop();
    });
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Stop the consumer loop. Pending items in the queue are discarded.
  void dispose() {
    _running = false;
    // Unblock any awaiting futures so the loop can exit cleanly.
    if (!_gate.isCompleted) _gate.complete();
    if (!_itemAvailable.isCompleted) _itemAvailable.complete();
    _queue.clear();
  }
}
