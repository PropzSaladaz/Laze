import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laze/presentation/core/themes/app_theme.dart';
import 'package:laze/presentation/home/widgets/mousepad.dart';

void main() {
  Future<void> showPad(WidgetTester tester, List<List<int>> events,
      {bool fullscreen = true}) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MousePad(
          fullscreen: fullscreen,
          sensitivity: 5,
          sendInput: (Uint8List input) => events.add(input.toList()),
        ),
      ),
    ));
  }

  tearDown(() {
    TestWidgetsFlutterBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('cancelling a held drag releases once and permits a fresh drag',
      (tester) async {
    final events = <List<int>>[];
    await showPad(tester, events);
    final first = await tester
        .startGesture(tester.getCenter(find.byType(MousePad)), pointer: 1);
    await tester.pump(const Duration(milliseconds: 450));
    expect(events, [
      [8, 0]
    ]);
    await first.cancel();
    await tester.pump(const Duration(milliseconds: 500));
    expect(events, [
      [8, 0],
      [9, 0]
    ]);
    final second = await tester
        .startGesture(tester.getCenter(find.byType(MousePad)), pointer: 2);
    await tester.pump(const Duration(milliseconds: 450));
    await second.up();
    await tester.pump();
    expect(events, [
      [8, 0],
      [9, 0],
      [8, 0],
      [9, 0]
    ]);
  });

  testWidgets('cancelling before the long press prevents a delayed mouse-down',
      (tester) async {
    final events = <List<int>>[];
    await showPad(tester, events);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(MousePad)));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.cancel();
    await tester.pump(const Duration(milliseconds: 500));
    expect(events, isEmpty);
  });

  testWidgets('disposing a held drag releases it once', (tester) async {
    final events = <List<int>>[];
    await showPad(tester, events);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(MousePad)));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpWidget(const SizedBox.shrink());
    await gesture.cancel();
    await tester.pump(const Duration(milliseconds: 500));
    expect(events, [
      [8, 0],
      [9, 0]
    ]);
  });

  testWidgets('disposing a pending long press cannot affect the next touchpad',
      (tester) async {
    final oldEvents = <List<int>>[];
    await showPad(tester, oldEvents);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(MousePad)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    final newEvents = <List<int>>[];
    await showPad(tester, newEvents);
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.cancel();
    expect(oldEvents, isEmpty);
    expect(newEvents, isEmpty);
  });

  testWidgets('backgrounding releases drag once and resets gesture state',
      (tester) async {
    final events = <List<int>>[];
    await showPad(tester, events);
    final gesture = await tester
        .startGesture(tester.getCenter(find.byType(MousePad)), pointer: 1);
    await tester.pump(const Duration(milliseconds: 450));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await gesture.up();
    await tester.pump();
    expect(events, [
      [8, 0],
      [9, 0]
    ]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final fresh = await tester
        .startGesture(tester.getCenter(find.byType(MousePad)), pointer: 2);
    await tester.pump(const Duration(milliseconds: 450));
    await fresh.up();
    await tester.pump();
    expect(events, [
      [8, 0],
      [9, 0],
      [8, 0],
      [9, 0]
    ]);
  });

  testWidgets('a cancelled two-finger gesture emits no right-click',
      (tester) async {
    final events = <List<int>>[];
    await showPad(tester, events);
    final center = tester.getCenter(find.byType(MousePad));
    final first = await tester.startGesture(center, pointer: 1);
    final second =
        await tester.startGesture(center + const Offset(20, 0), pointer: 2);
    await first.cancel();
    await second.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(events, isEmpty);
    await tester.tapAt(center);
    expect(events, [
      [4, 0]
    ]);
  });

  testWidgets('ordinary taps still click after a completed drag',
      (tester) async {
    final events = <List<int>>[];
    await showPad(tester, events);
    final center = tester.getCenter(find.byType(MousePad));
    final drag = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 450));
    await drag.up();
    await tester.pump();
    await tester.tapAt(center);
    expect(events, [
      [8, 0],
      [9, 0],
      [4, 0]
    ]);
  });

  testWidgets('drag cleanup uses the sender that received its mouse-down',
      (tester) async {
    final originalEvents = <List<int>>[];
    await showPad(tester, originalEvents);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(MousePad)));
    await tester.pump(const Duration(milliseconds: 450));
    final newEvents = <List<int>>[];
    await showPad(tester, newEvents);
    await gesture.cancel();
    expect(originalEvents, [
      [8, 0],
      [9, 0]
    ]);
    expect(newEvents, isEmpty);
  });

  testWidgets('closing the fullscreen pad releases its held drag',
      (tester) async {
    final events = <List<int>>[];
    await showPad(tester, events, fullscreen: false);
    await tester.tap(find.byIcon(Icons.fullscreen));
    await tester.pumpAndSettle();
    final pad = find.byType(MousePad).last;
    final gesture = await tester.startGesture(tester.getCenter(pad));
    await tester.pump(const Duration(milliseconds: 450));
    expect(events, [
      [8, 0]
    ]);
    Navigator.of(tester.element(pad)).pop();
    await tester.pumpAndSettle();
    await gesture.cancel();
    expect(events, [
      [8, 0],
      [9, 0]
    ]);
  });
}
