import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
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
      insetPadding: EdgeInsets.symmetric(horizontal: Dimens.spacing.xl),
      backgroundColor: appColors.surface_1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.radius.medium),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Dimens.spacing.lg,
            Dimens.spacing.lg,
            Dimens.spacing.lg,
            Dimens.spacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Disconnect',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appColors.text,
                  fontSize: Dimens.text.header,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Dimens.spacing.xs),
              Text(
                'Choose whether to disconnect from the computer or shut it down.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appColors.textMuted,
                  fontSize: Dimens.text.small,
                  height: 1.35,
                ),
              ),
              SizedBox(height: Dimens.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(appColors.surface_3),
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(
                            vertical: Dimens.button.ctaVerticalPadding,
                          ),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimens.radius.pill),
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
                  SizedBox(width: Dimens.spacing.sm),
                  Expanded(
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(appColors.error),
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(
                            vertical: Dimens.button.ctaVerticalPadding,
                          ),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimens.radius.pill),
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
