import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/services/server_connector.dart';

typedef Callback = void Function();

class ConnectionHeader extends StatelessWidget {
  final String connectionStatus;
  final Callback connect;
  final Callback cancelSearch;
  final Callback disconnect;
  final Callback turnOffPc;

  const ConnectionHeader({
    super.key,
    required this.connectionStatus,
    required this.connect,
    required this.cancelSearch,
    required this.disconnect,
    required this.turnOffPc,
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
                    connectionStatus,
                    style: TextStyle(
                      color: appColors.textMuted,
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (connectionStatus == ServerConnector.CONNECTED) ...[
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
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              StyledButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
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
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(255, 255, 255, 0.64),
                      offset: Offset(-2, -1),
                      blurRadius: 5,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(255, 255, 255, 0.57),
                      offset: Offset(-8, -3),
                      blurRadius: 9,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(255, 255, 255, 0.38),
                      offset: Offset(-18, -8),
                      blurRadius: 12,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(255, 255, 255, 0.18),
                      offset: Offset(-31, -14),
                      blurRadius: 14,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(255, 255, 255, 0.01),
                      offset: Offset(-49, -22),
                      blurRadius: 15,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(95, 95, 95, 0.012),
                      offset: Offset(36, 4),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(95, 95, 95, 0.01),
                      offset: Offset(23, 3),
                      blurRadius: 9,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(95, 95, 95, 0.05),
                      offset: Offset(13, 1),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(95, 95, 95, 0.09),
                      offset: Offset(6, 1),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(95, 95, 95, 0.1),
                      offset: Offset(1, 0),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _handlePrimaryAction(context),
                  icon: Icon(
                    connectionStatus == ServerConnector.SEARCHING
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
    if (connectionStatus == ServerConnector.CONNECTED) {
      showDialog(
        context: context,
        builder: (dialogContext) => _disconnectPopup(dialogContext),
      );
      return;
    }

    if (connectionStatus == ServerConnector.SEARCHING) {
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
