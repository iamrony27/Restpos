import 'package:flutter/material.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/animations/smooth_page_route.dart';
import '../../core/channels/native_api_channel.dart';
import '../../models/restaurant_profile.dart';
import 'wifi_debugging_guide_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final RestaurantProfile _profile = const RestaurantProfile();
  NativeDeviceInfo? _deviceInfo;
  NativeBatteryInfo? _batteryInfo;
  bool _printerConnected = true;

  @override
  void initState() {
    super.initState();
    _loadHardwareInfo();
  }

  Future<void> _loadHardwareInfo() async {
    final dev = await NativeApiChannel.getDeviceInfo();
    final bat = await NativeApiChannel.getBatteryInfo();
    if (mounted) {
      setState(() {
        _deviceInfo = dev;
        _batteryInfo = bat;
      });
    }
  }

  Future<void> _testPrint() async {
    await NativeApiChannel.triggerNativeHaptic();
    final sample = '''
    ================================
         TEST RECEIPT - ESC/POS
         SPICE GARDEN RESTAURANT
    ================================
    Date: ${DateTime.now().toString().split('.')[0]}
    Printer: Thermal 58mm / 80mm
    Status: CONNECTED & READY
    ================================
    ''';
    await NativeApiChannel.printReceiptNative(receiptText: sample);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test print dispatched to native Android printer service!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings & Hardware',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Wi-Fi Debugging Banner
          BouncingButton(
            onPressed: () {
              Navigator.push(
                context,
                SmoothPageRoute(page: const WifiDebuggingGuideScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.9),
                    theme.colorScheme.secondary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wi-Fi Debugging & Live UI Preview',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Connect your phone over Wi-Fi to see UI live as you build!',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Restaurant Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Restaurant Profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _buildProfileRow('Name', _profile.name),
                  _buildProfileRow('GSTIN', _profile.gstin),
                  _buildProfileRow('FSSAI License', _profile.fssai),
                  _buildProfileRow('UPI VPA', _profile.upiId),
                  _buildProfileRow('Phone', _profile.phone),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hardware & Printing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ESC/POS Thermal Printing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.print_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          const Text('Bluetooth Thermal Printer', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Switch(
                        value: _printerConnected,
                        onChanged: (val) => setState(() => _printerConnected = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  BouncingButton(
                    onPressed: _testPrint,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_rounded, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Dispatch Test Print',
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Native Android Platform Inspection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Native Android APIs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        onPressed: _loadHardwareInfo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_deviceInfo != null) ...[
                    _buildProfileRow('Device Model', _deviceInfo!.model),
                    _buildProfileRow('Manufacturer', _deviceInfo!.manufacturer),
                    _buildProfileRow('Android OS', '${_deviceInfo!.androidVersion} (API ${_deviceInfo!.sdkInt})'),
                    _buildProfileRow('Hardware ID', _deviceInfo!.deviceId),
                  ],
                  if (_batteryInfo != null)
                    _buildProfileRow('Battery', '${_batteryInfo!.levelPercent}% (${_batteryInfo!.isCharging ? 'Charging' : 'Discharging'})'),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.vibration_rounded, size: 18),
                    label: const Text('Test Native Haptic Feedback'),
                    onPressed: () => NativeApiChannel.triggerNativeHaptic(type: 'click'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Theme Settings
          Card(
            child: ListTile(
              title: const Text('Material 3 Dark Theme', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Switch between light and dark Material 3 palette'),
              trailing: Switch(
                value: widget.isDarkMode,
                onChanged: (_) => widget.onToggleTheme(),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
