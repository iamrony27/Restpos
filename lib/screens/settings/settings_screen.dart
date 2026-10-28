import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/animations/smooth_page_route.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/theme/color_schemes.dart';
import '../../providers/pos_provider.dart';
import '../setup/setup_wizard_screen.dart';
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
    final pos = Provider.of<PosProvider>(context, listen: false);
    final profile = pos.profile;
    await NativeApiChannel.triggerNativeHaptic();

    final sample = '''
    ================================
         TEST RECEIPT - ESC/POS
         ${profile.name.toUpperCase()}
       ${profile.tagline}
    --------------------------------
    FSSAI Lic: ${profile.fssai}
    GSTIN: ${profile.isGstEnabled ? profile.gstin : "Non-GST / Exempt"}
    Round-Off: ${profile.isRoundOffEnabled ? "ENABLED" : "DISABLED"}
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
          backgroundColor: CulinaryColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _editFssaiDialog(BuildContext context, PosProvider pos) {
    final controller = TextEditingController(text: pos.fssaiNumber);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit FSSAI License Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 14,
          decoration: const InputDecoration(
            labelText: '14-digit FSSAI number',
            prefixIcon: Icon(Icons.verified_user_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              pos.setFssaiNumber(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pos = context.watch<PosProvider>();
    final profile = pos.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings & Configuration',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Setup Wizard Card (Prominent CTA)
          BouncingButton(
            onPressed: () {
              Navigator.push(
                context,
                SmoothPageRoute(page: const SetupWizardScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CulinaryColors.tandoorOrange, CulinaryColors.flameOrange],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: CulinaryColors.tandoorOrange.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 22,
                    child: Icon(Icons.auto_fix_high_rounded, color: CulinaryColors.tandoorOrange, size: 24),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restaurant Setup Wizard',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Configure name, GST, FSSAI, round-off, and UPI payments',
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

          const SizedBox(height: 16),

          // Wi-Fi Debugging Guide Banner
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
                    CulinaryColors.royalBlue,
                    CulinaryColors.royalBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wi-Fi Debugging & Live UI Preview',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Connected to phone over wireless adb',
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

          // GST & Tax Compliance Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CulinaryColors.emeraldGreen.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.percent_rounded, color: CulinaryColors.emeraldGreen, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'GST Tax Invoicing',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: pos.isGstEnabled,
                        activeColor: CulinaryColors.emeraldGreen,
                        onChanged: (val) {
                          NativeApiChannel.triggerNativeHaptic();
                          pos.setGstEnabled(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pos.isGstEnabled
                        ? 'GST is ENABLED: Calculating CGST + SGST (${pos.gstRatePercent.toStringAsFixed(1)}%) on invoices.'
                        : 'GST is DISABLED: Non-GST / Tax-exempt mode (0% tax applied).',
                    style: TextStyle(
                      fontSize: 12,
                      color: pos.isGstEnabled ? Colors.grey.shade700 : Colors.orange.shade800,
                      fontWeight: pos.isGstEnabled ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),

                  if (pos.isGstEnabled) ...[
                    const Divider(height: 24),
                    const Text('Standard GST Slabs:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [5.0, 12.0, 18.0].map((rate) {
                        final selected = pos.gstRatePercent == rate;
                        return ChoiceChip(
                          label: Text('$rate% ${rate == 5.0 ? "(Restaurant)" : ""}'),
                          selected: selected,
                          selectedColor: CulinaryColors.emeraldGreen.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) pos.setGstRatePercent(rate);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    _buildProfileRow('GSTIN Number', profile.gstin),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Round Off & Billing Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CulinaryColors.amethystViolet.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.currency_rupee_rounded, color: CulinaryColors.amethystViolet, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Invoice Round-Off',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: pos.isRoundOffEnabled,
                        activeColor: CulinaryColors.amethystViolet,
                        onChanged: (val) {
                          NativeApiChannel.triggerNativeHaptic();
                          pos.setRoundOffEnabled(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pos.isRoundOffEnabled
                        ? 'Round-Off is ENABLED: Final payable bill rounds to nearest integer Rupee (± paise).'
                        : 'Round-Off is DISABLED: Exact paise billed to customer.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // FSSAI Food Safety License Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CulinaryColors.turmericGold.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: CulinaryColors.turmericGold, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'FSSAI Food Safety License',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        onPressed: () => _editFssaiDialog(context, pos),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('License No:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                          profile.fssai.isNotEmpty ? profile.fssai : '11223344556677',
                          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mandatory for all food business operators. Displayed on billing receipts and KOTs.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Restaurant Info Summary
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Restaurant Profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _buildProfileRow('Name', profile.name),
                  _buildProfileRow('Tagline', profile.tagline),
                  _buildProfileRow('UPI VPA', profile.upiId),
                  _buildProfileRow('Phone', profile.phone),
                  _buildProfileRow('Address', profile.address),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hardware & Printing
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            'Dispatch Test Print with FSSAI & GST',
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
