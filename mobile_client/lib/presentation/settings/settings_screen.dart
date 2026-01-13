import 'package:flutter/material.dart';
import 'package:mobile_client/data/repositories/device/device_settings_repository.dart';
import 'package:mobile_client/presentation/core/ui/controller_page.dart';
import 'package:mobile_client/presentation/core/ui/styled_button.dart';
import 'package:mobile_client/presentation/core/ui/styled_input.dart';
import 'package:mobile_client/presentation/core/ui/wide_styled_button.dart';
import 'package:mobile_client/presentation/core/themes/colors.dart';
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
    final deviceSettings = Provider.of<DeviceSettingsRepository>(context, listen: false);
    final deviceName = await deviceSettings.getDeviceName();
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
      final deviceSettings = Provider.of<DeviceSettingsRepository>(context, listen: false);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>();

    return ControllerPage(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - styled like ConnectionHeader
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'SETTINGS',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              StyledButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.close,
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: customColors!.shadowColorDark.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 7,
                                offset: const Offset(5, 2),
                              ),
                              BoxShadow(
                                color: customColors.shadowColorBright.withOpacity(1),
                                spreadRadius: 4,
                                blurRadius: 7,
                                offset: const Offset(-5, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.smartphone,
                                    color: colorScheme.onPrimary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Device Name',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'This name identifies your device on the server when multiple devices are connected.',
                                style: TextStyle(
                                  color: colorScheme.onPrimary.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: StyledInput(
                                  controller: _deviceNameController,
                                  hintText: 'Enter device name',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        WideStyledButton(
                          text: _isSaving ? 'Saving...' : 'Save',
                          textColor: colorScheme.onSecondary,
                          backgroundColor: colorScheme.secondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          onPressed: () {
                            if (!_isSaving) {
                              _saveDeviceName();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

