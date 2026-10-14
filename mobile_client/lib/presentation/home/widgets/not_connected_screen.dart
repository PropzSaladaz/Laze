import 'package:flutter/material.dart';
import 'package:laze/data/repositories/server/pairing_repository.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/core/ui/cta_button.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/presentation/pairing/pairing_widgets.dart';
import 'package:laze/services/server_connector.dart';

class NotConnectedScreen extends StatefulWidget {
  final ValueChanged<String> onConnect;
  final VoidCallback onOpenSettings;

  const NotConnectedScreen({
    super.key,
    required this.onConnect,
    required this.onOpenSettings,
  });

  @override
  State<NotConnectedScreen> createState() => _NotConnectedScreenState();
}

class _NotConnectedScreenState extends State<NotConnectedScreen> {
  late final Future<void> _pairingsReady;

  @override
  void initState() {
    super.initState();
    _pairingsReady = ServerConnector.pairings.init();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ServerConnector.pairings,
      builder: (context, _) => FutureBuilder<void>(
        future: _pairingsReady,
        builder: (context, snapshot) {
          final ready = snapshot.connectionState == ConnectionState.done;
          final computers = ready && !snapshot.hasError
              ? ServerConnector.pairings.computers
              : <PairedComputer>[];
          return _buildPage(context, ready, snapshot.hasError, computers);
        },
      ),
    );
  }

  Widget _buildPage(
      BuildContext context, bool ready, bool storageError,
      List<PairedComputer> computers) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final hasPairings = computers.isNotEmpty;
    final subtitle = storageError
        ? 'Unable to read your saved computers.'
        : !ready
            ? 'Checking your saved computers…'
            : hasPairings
                ? 'Choose a computer to control.'
                : 'Pair with Laze Desktop once by scanning its QR code.';

    return ControllerPage(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Settings button — top right
          Align(
            alignment: Alignment.topRight,
            child: StyledButton(
              onPressed: widget.onOpenSettings,
              icon: Icons.settings,
            ),
          ),
          SizedBox(height: hasPairings ? 32 : 50),

          // Heading
          Text(
            'NOT CONNECTED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appColors.textMuted,
              fontSize: Dimens.text.display,
              fontWeight: FontWeight.w200,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appColors.textMuted,
              fontSize: Dimens.text.body,
            ),
          ),

          SizedBox(height: hasPairings ? 32 : 50),

          // Paired computers scroll; the empty state keeps the illustration.
          Expanded(
            child: hasPairings
                ? ListView.separated(
                    itemCount: computers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) =>
                        _computerCard(context, computers[index]),
                  )
                : Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'assets/images/NoConnection.png',
                      fit: BoxFit.contain,
                    ),
                  ),
          ),

          if (!ready)
            Center(child: CircularProgressIndicator.adaptive())
          else if (storageError)
            const PairingNotice(
              message:
                  'Restart Laze and check your phone\'s secure storage before connecting.',
            )
          else if (hasPairings)
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: .75,
                child: PairingAction(
                  label: 'PAIR ANOTHER COMPUTER',
                  icon: Icons.qr_code_scanner,
                  onPressed: () => Navigator.pushNamed(context, '/pairing'),
                ),
              ),
            )
          else
            CtaButton(
              text: 'PAIR COMPUTER',
              onPressed: () => Navigator.pushNamed(context, '/pairing'),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _computerCard(BuildContext context, PairedComputer computer) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final scale = Theme.of(context).extension<DesignScale>()!;
    return PairingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.laptop_rounded, color: colors.primary, size: 32),
            SizedBox(width: scale.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    computer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: Dimens.text.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: scale.spaceXs),
                  Text(
                    computer.hosts.first,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: Dimens.text.tiny,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          SizedBox(height: scale.spaceLg),
          PairingAction(
            label: 'CONNECT',
            icon: Icons.link_rounded,
            primary: true,
            onPressed: () => widget.onConnect(computer.serverId),
          ),
        ],
      ),
    );
  }
}
