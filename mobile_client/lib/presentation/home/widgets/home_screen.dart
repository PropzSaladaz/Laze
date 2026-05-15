import 'package:flutter/material.dart';
import 'package:laze/data/repositories/shortcut/shortcut_repository.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/presentation/home/view_models/home_viewmodel.dart';
import 'package:laze/services/app_service_wrapper.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/home/widgets/connection_header.dart';
import 'package:laze/services/app_connection_status.dart';
import 'package:laze/presentation/home/widgets/not_connected_screen.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/home/widgets/mousepad.dart';
import 'package:laze/presentation/home/widgets/shortcuts_sheet.dart';
import 'package:provider/provider.dart';

import 'command_btns.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int sensitivity = 5;
  late final HomeViewModel _viewModel;
  final ValueNotifier<String> _feedbackNotifier = ValueNotifier('...');

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      shortcutsRepository:
          Provider.of<ShortcutsRepository>(context, listen: false),
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _feedbackNotifier.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final deviceSettings =
        Provider.of<DeviceSettingsRepository>(context, listen: false);
    final newSensitivity = await deviceSettings.getSensitivity();
    if (!mounted) return;
    setState(() {
      sensitivity = newSensitivity;
    });
  }

  void _updateSensitivity(int newSensitivity) {
    setState(() {
      sensitivity = newSensitivity;
    });
    final deviceSettings =
        Provider.of<DeviceSettingsRepository>(context, listen: false);
    deviceSettings.setSensitivity(newSensitivity);
  }

  @override
  Widget build(BuildContext context) {
    final wrapper = context.watch<AppServiceWrapper>();
    _checkAndShowErrorSnackbar(context, wrapper);

    return ChangeNotifierProvider<HomeViewModel>.value(
      value: _viewModel,
      child: wrapper.connectionStatus == AppConnectionStatus.notConnected
          ? NotConnectedScreen(
              onConnect: wrapper.connect,
              onOpenSettings: () =>
                  Navigator.pushNamed(context, '/settings').then((_) => _loadSettings()),
            )
          : _buildConnectedLayout(context, wrapper),
    );
  }

  Widget _buildConnectedLayout(
      BuildContext context, AppServiceWrapper wrapper) {
    return ControllerPage(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          ConnectionHeader(
            connectionStatus: wrapper.connectionStatus,
            connect: wrapper.connect,
            cancelSearch: wrapper.cancelSearch,
            disconnect: wrapper.disconnect,
            turnOffPc: wrapper.turnOffPc,
            onOpenSettings: () =>
                Navigator.pushNamed(context, '/settings').then((_) => _loadSettings()),
          ),
          const SizedBox(height: 24),
          _buildBody(context, wrapper),
        ],
      ),
      stackedBody: wrapper.connectionStatus == AppConnectionStatus.connected
          ? Positioned.fill(
              child: ShortcutsSheet(feedbackNotifier: _feedbackNotifier),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, AppServiceWrapper wrapper) {
    if (wrapper.connectionStatus == AppConnectionStatus.searching) {
      final appColors = Theme.of(context).extension<AppColors>()!;
      return Expanded(
        child: Center(
          child: CircularProgressIndicator.adaptive(
            backgroundColor: appColors.text,
          ),
        ),
      );
    }
    final mq = MediaQuery.of(context);
    final bottomInset =
        (mq.size.height - mq.padding.top - mq.padding.bottom) * 0.15 + 16;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset.toDouble()),
        child: Column(
          children: [
            Expanded(
              child: MousePad(
                fullscreen: false,
                sensitivity: sensitivity,
              ),
            ),
            const SizedBox(height: 40),
            CommandBtns(
              sensitivity: sensitivity,
              onSensitivityChanged: _updateSensitivity,
              feedbackNotifier: _feedbackNotifier,
            ),
          ],
        ),
      ),
    );
  }

  void _checkAndShowErrorSnackbar(
      BuildContext context, AppServiceWrapper wrapper) {
    if (wrapper.errorMessage != null) {
      final String msg = wrapper.errorMessage!;
      final appColors = Theme.of(context).extension<AppColors>()!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: appColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: "OK",
              onPressed: () {
                wrapper.dismissError();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      });
    }
  }
}
