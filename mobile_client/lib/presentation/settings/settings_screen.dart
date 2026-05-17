import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/presentation/core/ui/styled_input.dart';
import 'package:laze/presentation/core/ui/screen_header.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/themes/generated_theme.dart';

import 'package:laze/services/theme_notifier.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  bool _isLoading = true;

  int _sensitivity = 5;

  Timer? _deviceNameDebounce;
  String _lastSavedDeviceName = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _deviceNameController.addListener(_onDeviceNameChanged);
  }

  @override
  void dispose() {
    _deviceNameDebounce?.cancel();
    _deviceNameController.removeListener(_onDeviceNameChanged);
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final deviceSettings =
        Provider.of<DeviceSettingsRepository>(context, listen: false);
    final results = await Future.wait([
      deviceSettings.getDeviceName(),
      deviceSettings.getSensitivity(),
    ]);
    if (!mounted) return;
    setState(() {
      _deviceNameController.text = results[0] as String;
      _lastSavedDeviceName = _deviceNameController.text;
      _sensitivity = results[1] as int;
      _isLoading = false;
    });
  }

  void _onDeviceNameChanged() {
    _deviceNameDebounce?.cancel();
    _deviceNameDebounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = _deviceNameController.text.trim();
      if (trimmed.isEmpty || trimmed == _lastSavedDeviceName) return;
      unawaited(_saveDeviceName(trimmed));
    });
  }

  Future<void> _saveDeviceName(String name) async {
    try {
      final deviceSettings =
          Provider.of<DeviceSettingsRepository>(context, listen: false);
      await deviceSettings.setDeviceName(name);

      if (!mounted) return;
      _lastSavedDeviceName = name;
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to save device name: $e');
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

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final scale = Theme.of(context).extension<DesignScale>()!;

    return ControllerPage(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: const Text('SETTINGS'),
            actions: [
              StyledButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.close,
              ),
            ],
          ),
          SizedBox(height: scale.spaceLg),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DeviceNameCard(
                      appColors: appColors,
                      scale: scale,
                      controller: _deviceNameController,
                    ),
                    SizedBox(height: scale.spaceLg),
                    _ControlsCard(
                      appColors: appColors,
                      scale: scale,
                      sensitivity: _sensitivity,
                      onSensitivityChanged: (v) {
                        setState(() => _sensitivity = v);
                        Provider.of<DeviceSettingsRepository>(
                          context,
                          listen: false,
                        ).setSensitivity(v);
                      },
                    ),
                    SizedBox(height: scale.spaceLg),
                    _ThemeCard(appColors: appColors, scale: scale),
                    SizedBox(height: scale.spaceLg),
                    _HelpCard(appColors: appColors, scale: scale),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceNameCard extends StatelessWidget {
  final AppColors appColors;
  final DesignScale scale;
  final TextEditingController controller;

  const _DeviceNameCard({
    required this.appColors,
    required this.scale,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.spaceLg),
      decoration: BoxDecoration(
        color: appColors.surface_1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: appColors.surface_2,
                  borderRadius: BorderRadius.circular(scale.radiusMd),
                  border: Border.all(color: appColors.divider, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.smartphone, color: appColors.primary, size: 22),
              ),
              SizedBox(width: scale.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Name',
                      style: TextStyle(
                        color: appColors.text,
                        fontSize: Dimens.text.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: scale.space2xs),
                    Text(
                      'This name identifies your device on the server.',
                      style: TextStyle(
                        color: appColors.textMuted,
                        fontSize: Dimens.text.small,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: scale.spaceLg),
          Text(
            'Visible device label',
            style: TextStyle(
              color: appColors.textMuted,
              fontSize: Dimens.text.label,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: scale.spaceSm),
          Container(
            decoration: BoxDecoration(
              color: appColors.surface_2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appColors.divider, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StyledInput(
              controller: controller,
              hintText: 'Enter device name',
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppColors appColors;
  final DesignScale scale;

  const _ThemeCard({required this.appColors, required this.scale});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.spaceLg),
      decoration: BoxDecoration(
        color: appColors.surface_1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: appColors.surface_2,
                  borderRadius: BorderRadius.circular(scale.radiusMd),
                  border: Border.all(color: appColors.divider, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.palette_outlined,
                    color: appColors.primary, size: 22),
              ),
              SizedBox(width: scale.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        color: appColors.text,
                        fontSize: Dimens.text.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: scale.space2xs),
                    Text(
                      'Choose a colour scheme for the app.',
                      style: TextStyle(
                        color: appColors.textMuted,
                        fontSize: Dimens.text.small,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: scale.spaceLg),
          Row(
            children: AppThemeOption.values.map((option) {
              final selected = themeNotifier.option == option;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option != AppThemeOption.values.last
                        ? scale.spaceSm
                        : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => themeNotifier.setOption(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? appColors.primary
                            : appColors.surface_2,
                        borderRadius: BorderRadius.circular(scale.radiusMd),
                        border: Border.all(
                          color: selected
                              ? appColors.primary
                              : appColors.divider,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: selected
                              ? appColors.onPrimary
                              : appColors.textMuted,
                          fontSize: Dimens.text.label,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  final AppColors appColors;
  final DesignScale scale;
  final int sensitivity;
  final ValueChanged<int> onSensitivityChanged;

  const _ControlsCard({
    required this.appColors,
    required this.scale,
    required this.sensitivity,
    required this.onSensitivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.spaceLg),
      decoration: BoxDecoration(
        color: appColors.surface_1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: appColors.surface_2,
                  borderRadius: BorderRadius.circular(scale.radiusMd),
                  border: Border.all(color: appColors.divider, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.tune, color: appColors.primary, size: 22),
              ),
              SizedBox(width: scale.spaceMd),
              Text(
                'Controls',
                style: TextStyle(
                  color: appColors.text,
                  fontSize: Dimens.text.title,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: scale.spaceLg),

          // ── Sensitivity ──────────────────────────────────────────────
          _SettingLabel(
            appColors: appColors,
            label: 'Mouse Sensitivity',
            trailing: Text(
              '$sensitivity',
              style: TextStyle(
                color: appColors.primary,
                fontSize: Dimens.text.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: scale.spaceSm),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: appColors.primary,
              inactiveTrackColor: appColors.surface_3,
              thumbColor: appColors.primary,
              overlayColor: appColors.primary.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: sensitivity.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (v) => onSensitivityChanged(v.round()),
            ),
          ),

        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final AppColors appColors;
  final DesignScale scale;

  const _HelpCard({required this.appColors, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.spaceLg),
      decoration: BoxDecoration(
        color: appColors.surface_1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: appColors.surface_2,
                  borderRadius: BorderRadius.circular(scale.radiusMd),
                  border: Border.all(color: appColors.divider, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.help_outline,
                    color: appColors.primary, size: 22),
              ),
              SizedBox(width: scale.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help & Tutorial',
                      style: TextStyle(
                        color: appColors.text,
                        fontSize: Dimens.text.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: scale.space2xs),
                    Text(
                      'Replay the introduction to learn how Laze works.',
                      style: TextStyle(
                        color: appColors.textMuted,
                        fontSize: Dimens.text.small,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: scale.spaceLg),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/onboarding'),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: appColors.surface_2,
                borderRadius: BorderRadius.circular(scale.radiusMd),
                border: Border.all(color: appColors.divider, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                'View Tutorial',
                style: TextStyle(
                  color: appColors.text,
                  fontSize: Dimens.text.small,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          SizedBox(height: scale.spaceSm),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://lazecontroller.vercel.app/privacy'),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: appColors.surface_2,
                borderRadius: BorderRadius.circular(scale.radiusMd),
                border: Border.all(color: appColors.divider, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: appColors.textMuted,
                  fontSize: Dimens.text.small,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  final AppColors appColors;
  final String label;
  final Widget? trailing;

  const _SettingLabel({
    required this.appColors,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appColors.textMuted,
            fontSize: Dimens.text.label,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
