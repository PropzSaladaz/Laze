import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/core/ui/screen_header.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/presentation/pairing/pairing_widgets.dart';
import 'package:laze/services/app_service_wrapper.dart';
import 'package:laze/services/server_connector.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});
  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _scanner = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates);
  final _code = TextEditingController();
  bool _busy = false, _success = false;
  String? _error;
  Future<void> _pair(String code) async {
    if (_busy || code.trim().isEmpty) return;
    final wrapper = context.read<AppServiceWrapper>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _scanner.stop();
    } catch (_) {}
    if (!mounted) return;
    final success = await wrapper.pairWithQr(code);
    if (!mounted) return;
    if (success) {
      _success = true;
      _code.clear();
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = wrapper.consumeError() ??
            'Unable to pair. Generate a fresh code on your computer.';
      });
      try {
        await _scanner.start();
      } catch (_) {}
    }
  }

  Future<void> _retryCamera() async {
    if (_busy) return;
    try {
      await _scanner.start();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_busy && !_success) {
      ServerConnector.cancelPendingConnection(notify: false);
    }
    unawaited(_scanner.dispose());
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final scale = Theme.of(context).extension<DesignScale>()!;
    return ControllerPage(
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ScreenHeader(
            title: const Text('PAIR COMPUTER',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              Tooltip(
                  message: 'Close pairing',
                  child: StyledButton(
                      icon: Icons.close,
                      margin: EdgeInsets.zero,
                      width: 56,
                      height: 56,
                      onPressed: () => Navigator.of(context).pop())),
            ]),
        SizedBox(height: scale.spaceXl),
        Expanded(
            child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Connect to your computer',
                style: TextStyle(
                    color: colors.text,
                    fontSize: Dimens.text.title,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: scale.spaceSm),
            Text(
                'Choose Pair phone on your desktop, then hold its QR code inside the frame.',
                style: TextStyle(
                    color: colors.textMuted,
                    fontSize: Dimens.text.small,
                    height: 1.5)),
            SizedBox(height: scale.spaceXl),
            PairingCard(
                child: Column(children: [
              Row(children: [
                Icon(Icons.qr_code_scanner, size: 18, color: colors.primary),
                SizedBox(width: scale.spaceSm),
                Text('SCAN TO PAIR',
                    style: TextStyle(
                        color: colors.textMuted,
                        fontSize: Dimens.text.label,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8)),
                const Spacer(),
                if (_busy)
                  Text('Connecting…',
                      style: TextStyle(
                          color: colors.primary, fontSize: Dimens.text.tiny)),
              ]),
              SizedBox(height: scale.spaceLg),
              LayoutBuilder(
                  builder: (context, constraints) => SizedBox(
                        height: constraints.maxWidth.clamp(200.0, 320.0),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(Dimens.radius.small),
                          child: Stack(fit: StackFit.expand, children: [
                            MobileScanner(
                              controller: _scanner,
                              onDetect: (capture) {
                                for (final barcode in capture.barcodes) {
                                  final code = barcode.rawValue;
                                  if (code != null && code.isNotEmpty) {
                                    unawaited(_pair(code));
                                    break;
                                  }
                                }
                              },
                              errorBuilder: (context, error) => Container(
                                color: colors.surface_2,
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.videocam_off_outlined,
                                          color: colors.primary, size: 36),
                                      const SizedBox(height: 16),
                                      Text('Camera unavailable',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: colors.text,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Allow camera access in phone settings, or use a pairing code below.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: colors.textMuted,
                                              fontSize: Dimens.text.small,
                                              height: 1.4)),
                                    ]),
                              ),
                            ),
                            IgnorePointer(
                                child: CustomPaint(
                                    painter: _ScanFrame(colors.primary))),
                            if (_busy)
                              Container(
                                color: colors.bg.withValues(alpha: .88),
                                child: Center(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                      CircularProgressIndicator(
                                          color: colors.primary,
                                          strokeWidth: 3),
                                      const SizedBox(height: 20),
                                      Text('Pairing your computer…',
                                          style: TextStyle(
                                              color: colors.text,
                                              fontSize: Dimens.text.small,
                                              fontWeight: FontWeight.w600)),
                                    ])),
                              ),
                          ]),
                        ),
                      )),
              SizedBox(height: scale.spaceLg),
              Row(children: [
                Expanded(
                    child: Text('Pair once. Use Connect next time.',
                        style: TextStyle(
                            color: colors.textMuted,
                            fontSize: Dimens.text.tiny))),
                Tooltip(
                    message: 'Retry camera',
                    child: IconButton(
                        onPressed:
                            _busy ? null : () => unawaited(_retryCamera()),
                        icon: Icon(Icons.refresh_rounded,
                            color: colors.textMuted),
                        iconSize: 22)),
              ]),
            ])),
            if (_error != null) ...[
              SizedBox(height: scale.spaceLg),
              PairingNotice(message: _error!),
            ],
            SizedBox(height: scale.spaceXl),
            PairingCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(
                      horizontal: scale.spaceLg, vertical: scale.spaceSm),
                  childrenPadding: EdgeInsets.fromLTRB(
                      scale.spaceLg, 0, scale.spaceLg, scale.spaceLg),
                  leading: Icon(Icons.keyboard_outlined,
                      color: colors.primary, size: 22),
                  title: Text('Use a pairing code',
                      style: TextStyle(
                          color: colors.text,
                          fontSize: Dimens.text.small,
                          fontWeight: FontWeight.w700)),
                  subtitle: Text('If scanning is not available',
                      style: TextStyle(
                          color: colors.textMuted, fontSize: Dimens.text.tiny)),
                  iconColor: colors.textMuted,
                  collapsedIconColor: colors.textMuted,
                  children: [
                    TextField(
                      controller: _code,
                      enabled: !_busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLength: 4096,
                      cursorColor: colors.primary,
                      style: TextStyle(
                          color: colors.text, fontSize: Dimens.text.small),
                      decoration: InputDecoration(
                        hintText: 'Paste the code from your desktop',
                        counterText: '',
                        hintStyle: TextStyle(
                            color: colors.textMuted,
                            fontSize: Dimens.text.small),
                        filled: true,
                        fillColor: colors.surface_2,
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(scale.radiusMd),
                            borderSide: BorderSide(color: colors.divider)),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(scale.radiusMd)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(scale.radiusMd),
                            borderSide: BorderSide(color: colors.primary)),
                      ),
                    ),
                    SizedBox(height: scale.spaceLg),
                    PairingAction(
                        label: 'PAIR COMPUTER',
                        primary: true,
                        busy: _busy,
                        onPressed: () => unawaited(_pair(_code.text))),
                  ],
                ),
              ),
            ),
            SizedBox(height: scale.spaceLg),
          ]),
        )),
      ]),
    );
  }
}

class _ScanFrame extends CustomPainter {
  final Color color;
  _ScanFrame(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final frame = Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width * .76,
        height: size.height * .76);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const arm = 24.0;
    const radius = 12.0;
    final path = Path()
      ..moveTo(frame.left, frame.top + arm)
      ..lineTo(frame.left, frame.top + radius)
      ..quadraticBezierTo(frame.left, frame.top, frame.left + radius, frame.top)
      ..lineTo(frame.left + arm, frame.top)
      ..moveTo(frame.right - arm, frame.top)
      ..lineTo(frame.right - radius, frame.top)
      ..quadraticBezierTo(
          frame.right, frame.top, frame.right, frame.top + radius)
      ..lineTo(frame.right, frame.top + arm)
      ..moveTo(frame.right, frame.bottom - arm)
      ..lineTo(frame.right, frame.bottom - radius)
      ..quadraticBezierTo(
          frame.right, frame.bottom, frame.right - radius, frame.bottom)
      ..lineTo(frame.right - arm, frame.bottom)
      ..moveTo(frame.left + arm, frame.bottom)
      ..lineTo(frame.left + radius, frame.bottom)
      ..quadraticBezierTo(
          frame.left, frame.bottom, frame.left, frame.bottom - radius)
      ..lineTo(frame.left, frame.bottom - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanFrame oldDelegate) => oldDelegate.color != color;
}
