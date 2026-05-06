import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/presentation/core/ui/screen_header.dart';
import 'package:laze/services/app_connection_status.dart';

typedef Callback = void Function();

class ConnectionHeader extends StatelessWidget {
  final AppConnectionStatus connectionStatus;
  final Callback connect;
  final Callback cancelSearch;
  final Callback disconnect;
  final Callback turnOffPc;
  final Callback? onOpenSettings;

  const ConnectionHeader({
    super.key,
    required this.connectionStatus,
    required this.connect,
    required this.cancelSearch,
    required this.disconnect,
    required this.turnOffPc,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ScreenHeader(
        title: Row(
          children: [
            Expanded(
              child: Text(
                connectionStatus.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (connectionStatus == AppConnectionStatus.connected) ...[
              const SizedBox(width: 8),
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: appColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: appColors.onSuccess, width: 3),
                ),
              ),
            ],
          ],
        ),
        actions: [
          StyledButton(
            onPressed: () {
              if (onOpenSettings != null) {
                onOpenSettings!();
              } else {
                Navigator.pushNamed(context, '/settings');
              }
            },
            icon: Icons.settings,
          ),
          Container(
            width: 72,
            height: 60,
            decoration: BoxDecoration(
              color: appColors.error,
              border: Border.all(color: appColors.onError, width: 6),
              borderRadius: BorderRadius.circular(999),
              boxShadow: AppShadows.raisedControl(appColors),
            ),
            child: IconButton(
              onPressed: () => _handlePrimaryAction(context),
              icon: Icon(
                connectionStatus == AppConnectionStatus.searching
                    ? Icons.cancel
                    : Icons.power_settings_new,
                color: appColors.textInverse,
              ),
              iconSize: 30,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePrimaryAction(BuildContext context) {
    if (connectionStatus == AppConnectionStatus.connected) {
      showDialog(
        context: context,
        builder: (dialogContext) => _disconnectPopup(dialogContext),
      );
      return;
    }

    if (connectionStatus == AppConnectionStatus.searching) {
      cancelSearch();
      return;
    }

    connect();
  }

  Widget _disconnectPopup(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      backgroundColor: appColors.surface_1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Disconnect',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose whether to disconnect from the computer or shut it down.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appColors.textMuted,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(appColors.muted),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 14),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      onPressed: () {
                        disconnect();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Disconnect',
                        style: TextStyle(
                          color: appColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(appColors.error),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 14),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      onPressed: () {
                        turnOffPc();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Turn OFF PC',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: appColors.onError,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
