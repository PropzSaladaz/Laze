import 'package:flutter/material.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/core/ui/cta_button.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/presentation/core/ui/styled_input.dart';
import 'package:laze/presentation/core/themes/app_shadows.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceName();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceName() async {
    final deviceSettings =
        Provider.of<DeviceSettingsRepository>(context, listen: false);
    final deviceName = await deviceSettings.getDeviceName();
    if (!mounted) {
      return;
    }

    setState(() {
      _deviceNameController.text = deviceName;
      _isLoading = false;
    });
  }

  Future<void> _saveDeviceName() async {
    if (_deviceNameController.text.trim().isEmpty) {
      _showError('Device name cannot be empty');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final deviceSettings =
          Provider.of<DeviceSettingsRepository>(context, listen: false);
      await deviceSettings.setDeviceName(_deviceNameController.text.trim());

      if (mounted) {
        _showSuccess('Device name saved successfully');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save device name: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scale = Theme.of(context).extension<DesignScale>()!;

    return ControllerPage(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    borderRadius: BorderRadius.circular(scale.radiusPill),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SETTINGS',
                    style: TextStyle(
                      color: appColors.textMuted,
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              StyledButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.close,
              ),
            ],
          ),
          SizedBox(height: scale.spaceXl),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: appColors.text),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    clipBehavior: Clip.none,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(
                                            scale.spaceXl,
                                          ),
                                          decoration: BoxDecoration(
                                            color: appColors.surface_1,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            border: Border.all(
                                              color: appColors.divider,
                                              width: 1,
                                            ),
                                            boxShadow: AppShadows.raisedControl,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          appColors.surface_2,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        scale.radiusLg,
                                                      ),
                                                      border: Border.all(
                                                        color:
                                                            appColors.divider,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.smartphone,
                                                      color: appColors.primary,
                                                      size: 28,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: scale.spaceLg,
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Device Name',
                                                          style: TextStyle(
                                                            color:
                                                                appColors.text,
                                                            fontSize: 24,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: scale.spaceSm,
                                                        ),
                                                        Text(
                                                          'This name identifies your device on the server when multiple devices are connected.',
                                                          style: TextStyle(
                                                            color: appColors
                                                                .textMuted,
                                                            fontSize: 15,
                                                            height: 1.35,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: scale.spaceXl,
                                              ),
                                              Text(
                                                'Visible device label',
                                                style: TextStyle(
                                                  color: appColors.textMuted,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              SizedBox(height: scale.spaceSm),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: appColors.surface_2,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: appColors.divider,
                                                    width: 1,
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                ),
                                                child: StyledInput(
                                                  controller:
                                                      _deviceNameController,
                                                  hintText: 'Enter device name',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: scale.spaceXl),
                                CtaButton(
                                  text: _isSaving ? 'SAVING' : 'SAVE',
                                  onPressed:
                                      _isSaving ? () {} : _saveDeviceName,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
