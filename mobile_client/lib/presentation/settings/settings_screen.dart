import 'package:flutter/material.dart';
import 'package:laze/data/repositories/device/device_settings_repository.dart';
import 'package:laze/presentation/core/ui/controller_page.dart';
import 'package:laze/presentation/core/ui/cta_button.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';
import 'package:laze/presentation/core/ui/styled_input.dart';
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
  bool _isSaving = false;

  int _sensitivity = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
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
      _sensitivity = results[1] as int;
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
        _showSuccess('Settings updated');
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 460;
              final titleBanner = Container(
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
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appColors.textMuted,
                    fontSize: isCompact ? 24 : 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
              final closeButton = StyledButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.close,
              );

              return isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        titleBanner,
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: closeButton,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: titleBanner),
                        const SizedBox(width: 12),
                        closeButton,
                      ],
                    );
            },
          ),
          SizedBox(height: scale.spaceXl),
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
                    SizedBox(height: scale.spaceXl),
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
                    SizedBox(height: scale.spaceXl),
                    _ThemeCard(appColors: appColors, scale: scale),
                  ],
                ),
              ),
            ),
            SizedBox(height: scale.spaceXl),
            CtaButton(
              text: _isSaving ? 'SAVING' : 'SAVE',
              onPressed: _isSaving ? () {} : _saveDeviceName,
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
      padding: EdgeInsets.all(scale.spaceXl),
      decoration: BoxDecoration(
        color: appColors.surface_1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: appColors.surface_2,
                  borderRadius: BorderRadius.circular(scale.radiusLg),
                  border: Border.all(color: appColors.divider, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.smartphone, color: appColors.primary, size: 28),
              ),
              SizedBox(width: scale.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Name',
                      style: TextStyle(
                        color: appColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: scale.spaceSm),
                    Text(
                      'This name identifies your device on the server when multiple devices are connected.',
                      style: TextStyle(
                        color: appColors.textMuted,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: scale.spaceXl),
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
      padding: EdgeInsets.all(scale.spaceXl),
      decoration: BoxDecoration(
        color: appColors.surface_1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: appColors.surface_2,
                  borderRadius: BorderRadius.circular(scale.radiusLg),
                  border: Border.all(color: appColors.divider, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.palette_outlined,
                    color: appColors.primary, size: 28),
              ),
              SizedBox(width: scale.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        color: appColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: scale.spaceSm),
                    Text(
                      'Choose a colour scheme for the app.',
                      style: TextStyle(
                        color: appColors.textMuted,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: scale.spaceXl),
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
                          fontSize: 13,
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
      padding: EdgeInsets.all(scale.spaceXl),
      decoration: BoxDecoration(
        color: appColors.surface_1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: appColors.surface_2,
                  borderRadius: BorderRadius.circular(scale.radiusLg),
                  border: Border.all(color: appColors.divider, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.tune, color: appColors.primary, size: 28),
              ),
              SizedBox(width: scale.spaceLg),
              Text(
                'Controls',
                style: TextStyle(
                  color: appColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: scale.spaceXl),

          // ── Sensitivity ──────────────────────────────────────────────
          _SettingLabel(
            appColors: appColors,
            label: 'Mouse Sensitivity',
            trailing: Text(
              '$sensitivity',
              style: TextStyle(
                color: appColors.primary,
                fontSize: 16,
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
