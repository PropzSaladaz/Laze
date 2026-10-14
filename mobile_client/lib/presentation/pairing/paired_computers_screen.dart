import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/core/ui/screen_header.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/presentation/pairing/pairing_widgets.dart';
import 'package:laze/services/app_connection_status.dart';
import 'package:laze/services/server_connector.dart';
import 'package:laze/services/app_service_wrapper.dart';

class PairedComputersScreen extends StatefulWidget {
  const PairedComputersScreen({super.key});
  @override
  State<PairedComputersScreen> createState() => _PairedComputersScreenState();
}

class _PairedComputersScreenState extends State<PairedComputersScreen> {
  late final Future<void> _ready = ServerConnector.pairings.init();
  final _removing = <String>{};
  String? _error;

  Future<void> _forget(String id) async {
    if (_removing.contains(id)) return;
    setState(() {
      _removing.add(id);
      _error = null;
    });
    try {
      await context.read<AppServiceWrapper>().forgetComputer(id);
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'Unable to forget this computer. Please try again.');
    } finally {
      if (mounted) setState(() => _removing.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final scale = Theme.of(context).extension<DesignScale>()!;
    final wrapper = context.watch<AppServiceWrapper>();
    return ControllerPage(
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ScreenHeader(title: const Text('COMPUTERS'), actions: [
          Tooltip(
              message: 'Close paired computers',
              child: StyledButton(
                  icon: Icons.close,
                  margin: EdgeInsets.zero,
                  width: 56,
                  height: 56,
                  onPressed: () => Navigator.of(context).pop())),
        ]),
        SizedBox(height: scale.spaceXl),
        Expanded(
            child: FutureBuilder<void>(
          future: _ready,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                  child: CircularProgressIndicator(color: colors.primary));
            }
            if (snapshot.hasError) {
              return const PairingNotice(
                  message:
                      'Unable to read saved computers. Restart Laze and check phone secure storage.');
            }
            return AnimatedBuilder(
              animation: ServerConnector.pairings,
              builder: (context, _) {
                final computers = ServerConnector.pairings.computers;
                return ListView(children: [
                  Text('Your paired computers',
                      style: TextStyle(
                          color: colors.text,
                          fontSize: Dimens.text.title,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: scale.spaceSm),
                  Text(
                      'Pair once, then reconnect with Connect on the home screen.',
                      style: TextStyle(
                          color: colors.textMuted,
                          fontSize: Dimens.text.small,
                          height: 1.5)),
                  SizedBox(height: scale.spaceXl),
                  if (_error != null) ...[
                    PairingNotice(message: _error!),
                    SizedBox(height: scale.spaceLg),
                  ],
                  if (computers.isEmpty)
                    PairingCard(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(children: [
                        Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                                color: colors.surface_2,
                                borderRadius: BorderRadius.circular(
                                    Dimens.radius.medium)),
                            child: Icon(Icons.laptop_rounded,
                                size: 36, color: colors.primary)),
                        const SizedBox(height: 20),
                        Text('No computers paired yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: colors.text,
                                fontSize: Dimens.text.title,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                            'Pair with your desktop once. Laze will remember it.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: colors.textMuted,
                                fontSize: Dimens.text.small,
                                height: 1.5)),
                      ]),
                    )),
                  ...computers.map((computer) {
                    final connected = wrapper.connectionStatus ==
                            AppConnectionStatus.connected &&
                        ServerConnector.activeServerId == computer.serverId;
                    final removing = _removing.contains(computer.serverId);
                    return Padding(
                      padding: EdgeInsets.only(bottom: scale.spaceLg),
                      child: PairingCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                      color: colors.surface_2,
                                      borderRadius:
                                          BorderRadius.circular(scale.radiusMd),
                                      border:
                                          Border.all(color: colors.divider)),
                                  child: Icon(Icons.laptop_rounded,
                                      color: colors.primary, size: 24)),
                              SizedBox(width: scale.spaceMd),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(computer.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: colors.text,
                                            fontSize: Dimens.text.body,
                                            fontWeight: FontWeight.w700)),
                                    SizedBox(height: scale.spaceXs),
                                    Text(computer.hosts.first,
                                        style: TextStyle(
                                            color: colors.textMuted,
                                            fontSize: Dimens.text.tiny)),
                                  ])),
                            ]),
                            SizedBox(height: scale.spaceLg),
                            Row(children: [
                              Icon(
                                  connected
                                      ? Icons.check_circle_outline
                                      : Icons.link_rounded,
                                  color: connected
                                      ? colors.success
                                      : colors.textMuted,
                                  size: 16),
                              SizedBox(width: scale.spaceSm),
                              Text(connected ? 'Connected' : 'Paired',
                                  style: TextStyle(
                                      color: connected
                                          ? colors.success
                                          : colors.textMuted,
                                      fontSize: Dimens.text.label,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              if (removing)
                                SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: colors.primary))
                              else
                                TextButton.icon(
                                  onPressed: () =>
                                      unawaited(_forget(computer.serverId)),
                                  icon: const Icon(Icons.link_off_rounded,
                                      size: 18),
                                  label: const Text('Forget'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: colors.error,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      minimumSize: const Size(0, 44),
                                      shape: const StadiumBorder()),
                                ),
                            ]),
                          ])),
                    );
                  }),
                  SizedBox(height: scale.spaceXl),
                  PairingAction(
                      label: 'PAIR A COMPUTER',
                      icon: Icons.qr_code_scanner,
                      primary: true,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/pairing')),
                  SizedBox(height: scale.spaceLg),
                  Text(
                      'Use Connect on the home screen to find a saved computer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: colors.textMuted,
                          fontSize: Dimens.text.tiny,
                          height: 1.5)),
                  SizedBox(height: scale.spaceLg),
                ]);
              },
            );
          },
        )),
      ]),
    );
  }
}
