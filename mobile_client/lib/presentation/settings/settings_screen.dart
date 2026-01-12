import 'package:flutter/material.dart';
import 'package:mobile_client/data/repositories/device/device_settings_repository.dart';
import 'package:mobile_client/presentation/core/ui/controller_page.dart';
import 'package:mobile_client/presentation/core/ui/styled_input.dart';
import 'package:mobile_client/presentation/core/ui/wide_styled_button.dart';
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

    return ControllerPage(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme.onPrimary,
                  size: 30,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                'Settings',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 35,
                  fontWeight: FontWeight.w500,
                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Name',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'This name will be shown to the server and helps identify your device when multiple devices are connected.',
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        StyledInput(
                          controller: _deviceNameController,
                          hintText: 'Enter device name',
                          inputTitle: 'Device Name',
                        ),
                        const SizedBox(height: 30),
                        WideStyledButton(
                          text: _isSaving ? 'Saving...' : 'Save',
                          onPressed: _isSaving ? null : _saveDeviceName,
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
