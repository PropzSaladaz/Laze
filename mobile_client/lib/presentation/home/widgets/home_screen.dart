import 'package:flutter/material.dart';
import 'package:laze/data/repositories/shortcut/shortcut_repository.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/presentation/home/view_models/home_viewmodel.dart';
import 'package:laze/services/server_connector.dart';
import 'package:laze/services/app_service_wrapper.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:laze/presentation/home/widgets/connection_header.dart';
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
  bool showShortcutsScrollableSheet = false;
  int sensitivity = 5; // Default sensitivity
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final deviceSettings =
        Provider.of<DeviceSettingsRepository>(context, listen: false);
    _loadSensitivity(deviceSettings);

    _viewModel = HomeViewModel(
      shortcutsRepository:
          Provider.of<ShortcutsRepository>(context, listen: false),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadSensitivity(DeviceSettingsRepository settings) async {
    final savedSensitivity = await settings.getSensitivity();
    if (mounted) {
      setState(() {
        sensitivity = savedSensitivity;
      });
    }
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
      child: ControllerPage(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            ConnectionHeader(
              connectionStatus: wrapper.connectionStatus,
              connect: wrapper.connect,
              cancelSearch: wrapper.cancelSearch,
              disconnect: wrapper.disconnect,
              turnOffPc: wrapper.turnOffPc,
            ),
            const SizedBox(
              height: 23,
            ),

            // PAGE BODY
            () {
              // NOT CONNECTED
              if (wrapper.connectionStatus == ServerConnector.NOT_CONNECTED) {
                return Expanded(
                  child: Center(
                      child: Image.asset("assets/images/NoConnection.png")),
                );

                // LOOKING
              } else if (wrapper.connectionStatus ==
                  ServerConnector.SEARCHING) {
                final appColors = Theme.of(context).extension<AppColors>()!;
                return Expanded(
                  child: Center(
                    child: CircularProgressIndicator.adaptive(
                      backgroundColor: appColors.text,
                    ),
                  ),
                );

                // CONNECTED
              } else {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MousePad(
                          fullscreen: false,
                          sensitivity: sensitivity,
                        ),
                        const SizedBox(height: 15),
                        CommandBtns(
                            sensitivity: sensitivity,
                            onSensitivityChanged: _updateSensitivity,
                            onShowShortcutsSheet: () {
                              setState(() {
                                showShortcutsScrollableSheet = true;
                              });
                            }),
                      ],
                    ),
                  ),
                );
              }
            }()
            // BODY
          ],
        ),
        stackedBody:
            // SCROLABLE SHORTCUTS
            Visibility(
                visible: showShortcutsScrollableSheet,
                child: Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  // Propagates changes to widgets in the tree
                  child: ShortcutsSheet(
                    isVisible: showShortcutsScrollableSheet,
                    closeScrollableSheets: () {
                      setState(() {
                        showShortcutsScrollableSheet = false;
                      });
                    },
                  ),
                )),
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
