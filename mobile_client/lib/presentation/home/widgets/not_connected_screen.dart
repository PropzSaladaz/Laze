import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/core/ui/cta_button.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';

class NotConnectedScreen extends StatelessWidget {
  final VoidCallback onConnect;
  final VoidCallback onOpenSettings;

  const NotConnectedScreen({
    super.key,
    required this.onConnect,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return ControllerPage(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Settings button — top right
          Align(
            alignment: Alignment.topRight,
            child: StyledButton(
              onPressed: onOpenSettings,
              icon: Icons.settings,
            ),
          ),
          const SizedBox(height: 50),

          // Heading
          Text(
            'NOT CONNECTED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appColors.textMuted,
              fontSize: 40,
              fontWeight: FontWeight.w100,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Open the Laze desktop app on your computer and press connect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appColors.textMuted,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 50),

          // Graphic — fills remaining space
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Image.asset('assets/images/NoConnection.png'),
            ),
          ),

          // CTA button
          CtaButton(
            text: 'CONNECT',
            onPressed: onConnect,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
