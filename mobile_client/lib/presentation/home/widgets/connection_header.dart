import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: appColors.border,
                border: Border.all(color: appColors.divider, width: 1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Text(
                    connectionStatus.label,
                    style: TextStyle(
                      color: appColors.textMuted,
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
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
                        border:
                            Border.all(color: appColors.onSuccess, width: 3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
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
              const SizedBox(width: 10),
              Container(
                width: 84,
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
                  iconSize: 35,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
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

    return AlertDialog(
      alignment: Alignment.center,
      backgroundColor: appColors.surface_1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        'Disconnect',
        style: TextStyle(color: appColors.text),
      ),
      actions: [
        TextButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(appColors.muted),
          ),
          onPressed: () {
            disconnect();
            Navigator.of(context).pop();
          },
          child: Text(
            'Disconnect',
            style: TextStyle(
              color: appColors.text,
            ),
          ),
        ),
        TextButton(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(appColors.error),
          ),
          onPressed: () {
            turnOffPc();
            Navigator.of(context).pop();
          },
          child: Text(
            'Turn OFF PC',
            style: TextStyle(
              color: appColors.onError,
            ),
          ),
        ),
      ],
    );
  }
}
