import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/animations/smooth_page_route.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/theme/color_schemes.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/table_provider.dart';
import '../../services/backup_restore_service.dart';
import '../reports/sales_report_screen.dart';
import '../setup/setup_wizard_screen.dart';
import 'wifi_debugging_guide_screen.dart';
import '../../widgets/developer_support_section.dart';
import '../../widgets/thermal_slip_preview_dialog.dart';
import '../../core/utils/app_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _printerConnected = false;
  String? _connectedPrinterName;
  String? _connectedPrinterMac;
  bool _isConnectingPrinter = false;
  bool _is80mmPaper = false;

  @override
  void initState() {
    super.initState();
    _loadHardwareInfo();
    _loadPrinterPreference();
  }

  Future<void> _loadPrinterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMac = prefs.getString('bt_printer_mac');
    final savedName = prefs.getString('bt_printer_name');
    final is80 = prefs.getBool('bt_printer_80mm') ?? false;
    final isConnected = await NativeApiChannel.isPrinterConnected();

    if (mounted) {
      setState(() {
        _connectedPrinterMac = savedMac;
        _connectedPrinterName = savedName;
        _is80mmPaper = is80;
        _printerConnected = isConnected;
      });
    }

    if (savedMac != null && !isConnected) {
      final ok = await NativeApiChannel.connectBluetoothPrinter(savedMac);
      if (mounted) {
        setState(() => _printerConnected = ok);
      }
    }
  }

  Future<void> _connectToPrinter(String mac, String name) async {
    setState(() => _isConnectingPrinter = true);
    AppNotification.showInfo(context, 'Connecting to $name...', title: 'Bluetooth Printer');

    final success = await NativeApiChannel.connectBluetoothPrinter(mac);
    if (!mounted) return;

    setState(() {
      _isConnectingPrinter = false;
      _printerConnected = success;
      if (success) {
        _connectedPrinterMac = mac;
        _connectedPrinterName = name;
      }
    });

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bt_printer_mac', mac);
      await prefs.setString('bt_printer_name', name);
      if (mounted) {
        AppNotification.showSuccess(context, 'Connected to $name ($mac)', title: 'Thermal Printer Online 🖨️');
      }
    } else {
      if (mounted) {
        AppNotification.showError(
          context,
          'Could not connect to $name. Please ensure printer is powered on and paired.',
          title: 'Connection Failed',
        );
      }
    }
  }

  Future<void> _disconnectPrinter() async {
    await NativeApiChannel.disconnectBluetoothPrinter();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bt_printer_mac');
    await prefs.remove('bt_printer_name');

    if (mounted) {
      setState(() {
        _printerConnected = false;
        _connectedPrinterMac = null;
        _connectedPrinterName = null;
      });
      AppNotification.showInfo(context, 'Thermal printer disconnected.', title: 'Printer Offline');
    }
  }

  Future<void> _showPrinterSelectionSheet() async {
    await NativeApiChannel.triggerNativeHaptic();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FutureBuilder<List<Map<String, String>>>(
              future: NativeApiChannel.getBondedBluetoothDevices(),
              builder: (context, snapshot) {
                final theme = Theme.of(context);
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final devices = snapshot.data ?? [];

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bluetooth_searching_rounded, color: theme.colorScheme.primary),
                              const SizedBox(width: 10),
                              Text(
                                'Select Thermal Printer',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Refresh paired devices',
                            onPressed: () => setSheetState(() {}),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose your paired Bluetooth thermal receipt printer (58mm/80mm):',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (devices.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.bluetooth_disabled_rounded, size: 40, color: theme.colorScheme.outline),
                              const SizedBox(height: 10),
                              const Text(
                                'No Paired Bluetooth Devices Found',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Turn on your thermal printer and pair it in Android Bluetooth Settings first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  NativeApiChannel.openBluetoothSettings();
                                },
                                icon: const Icon(Icons.settings_bluetooth_rounded, size: 18),
                                label: const Text('Open Bluetooth Settings'),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: devices.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final dev = devices[idx];
                            final name = dev['name'] ?? 'Unknown Device';
                            final mac = dev['address'] ?? '';
                            final isCurrent = _connectedPrinterMac == mac && _printerConnected;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isCurrent
                                    ? CulinaryColors.emeraldGreen.withOpacity(0.15)
                                    : theme.colorScheme.surfaceContainerHigh,
                                child: Icon(
                                  Icons.print_rounded,
                                  color: isCurrent ? CulinaryColors.emeraldGreen : theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                  color: isCurrent ? CulinaryColors.emeraldGreen : null,
                                ),
                              ),
                              subtitle: Text(mac, style: const TextStyle(fontSize: 12)),
                              trailing: isCurrent
                                  ? const Icon(Icons.check_circle_rounded, color: CulinaryColors.emeraldGreen)
                                  : FilledButton.tonal(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        await _connectToPrinter(mac, name);
                                      },
                                      child: const Text('Connect'),
                                    ),
                              onTap: isCurrent
                                  ? null
                                  : () async {
                                      Navigator.pop(ctx);
                                      await _connectToPrinter(mac, name);
                                    },
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          NativeApiChannel.openBluetoothSettings();
                        },
                        icon: const Icon(Icons.settings_bluetooth_rounded, size: 18),
                        label: const Text('Pair New Printer in Bluetooth Settings'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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

    final widthText = _is80mmPaper ? "80mm (Wide / 48 col)" : "58mm (Standard / 32 col)";
    final sample = '''
================================
     TEST RECEIPT - ESC/POS
     ${profile.name.toUpperCase()}
   ${profile.tagline}
   ${profile.address}
   Ph: ${profile.phone}
--------------------------------
FSSAI Lic: ${profile.fssai.isNotEmpty ? profile.fssai : "11223344556677"}
GSTIN: ${profile.isGstEnabled ? profile.gstin : "Non-GST / Exempt"}
Round-Off: ${profile.isRoundOffEnabled ? "ENABLED" : "DISABLED"}
Date: ${DateTime.now().toString().split('.')[0]}
Paper: $widthText
Printer: ${_connectedPrinterName ?? "Generic Thermal"}
Status: ${_printerConnected ? "ONLINE & READY" : "PREVIEW SIMULATION"}
================================
''';

    if (_printerConnected) {
      final printed = await NativeApiChannel.printReceiptNative(
        receiptText: sample,
        printerMacAddress: _connectedPrinterMac,
      );
      if (mounted) {
        if (printed) {
          AppNotification.showSuccess(
            context,
            'Dispatched test ESC/POS receipt to ${_connectedPrinterName ?? "printer"}.',
            title: 'Print Successful 🖨️',
          );
        } else {
          AppNotification.showError(
            context,
            'Failed to dispatch ESC/POS bytes. Verify printer power and paper roll.',
            title: 'Printer Communication Failed',
          );
        }
      }
    }

    if (!mounted) return;
    await ThermalSlipPreviewDialog.show(
      context,
      profile: profile,
      customReceiptText: sample,
      title: 'Test Receipt Preview',
    );
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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

          const SizedBox(height: 16),

          // Sales & GST PDF Tax Report Card (Prominent CTA)
          BouncingButton(
            onPressed: () {
              Navigator.push(
                context,
                SmoothPageRoute(page: const SalesReportScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CulinaryColors.flameOrange, CulinaryColors.tandoorSpice],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: CulinaryColors.flameOrange.withOpacity(0.3),
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
                    child: Icon(Icons.picture_as_pdf_rounded, color: CulinaryColors.flameOrange, size: 24),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales & GST Tax PDF Reports',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Monthly, Quarterly & Yearly statutory filing statements',
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
                    const SizedBox(height: 14),
                    // Tax Mode: Inclusive vs Exclusive
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tax Treatment Mode',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                pos.isTaxInclusive
                                    ? 'Prices INCLUDE GST (Base + Tax = Menu Price)'
                                    : 'Prices EXCLUDE GST (GST added at billing)',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Excl.'),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Incl.'),
                            ),
                          ],
                          selected: {pos.isTaxInclusive},
                          onSelectionChanged: (set) {
                            NativeApiChannel.triggerNativeHaptic();
                            pos.setTaxInclusive(set.first);
                          },
                        ),
                      ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.print_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('ESC/POS Thermal Printing',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _printerConnected
                              ? CulinaryColors.emeraldGreen.withOpacity(0.12)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _printerConnected
                                ? CulinaryColors.emeraldGreen.withOpacity(0.4)
                                : theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _printerConnected
                                    ? CulinaryColors.emeraldGreen
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _printerConnected ? 'CONNECTED' : 'NOT CONNECTED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _printerConnected
                                    ? CulinaryColors.emeraldGreen
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_printerConnected && _connectedPrinterName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CulinaryColors.emeraldGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CulinaryColors.emeraldGreen.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bluetooth_connected_rounded, color: CulinaryColors.emeraldGreen, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _connectedPrinterName!,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                if (_connectedPrinterMac != null)
                                  Text(
                                    _connectedPrinterMac!,
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _disconnectPrinter,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            child: const Text('Disconnect'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Text(
                      'Connect a wireless Bluetooth thermal receipt printer for instant KOT & customer billing slips.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isConnectingPrinter ? null : _showPrinterSelectionSheet,
                          icon: _isConnectingPrinter
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.bluetooth_searching_rounded, size: 18),
                          label: Text(_printerConnected ? 'Change Printer' : 'Select / Connect Thermal Printer'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Paper Width:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('58mm (2-inch)'),
                        selected: !_is80mmPaper,
                        onSelected: (selected) async {
                          if (selected) {
                            setState(() => _is80mmPaper = false);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('bt_printer_80mm', false);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('80mm (3-inch)'),
                        selected: _is80mmPaper,
                        onSelected: (selected) async {
                          if (selected) {
                            setState(() => _is80mmPaper = true);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('bt_printer_80mm', true);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                            _printerConnected
                                ? 'Print ESC/POS Test Slip & Open Preview'
                                : 'Preview Test Receipt Slip',
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

          // Backup & Restore Database Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CulinaryColors.flameOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.backup_rounded, color: CulinaryColors.flameOrange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backup & Restore Data',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Export dishes, categories, orders & tables to device JSON file',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CulinaryColors.flameOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: const Text('Backup Now', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () => _handleBackupFlow(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.restore_page_rounded, size: 18),
                          label: const Text('Restore Data', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () => _handleRestoreFlow(context),
                        ),
                      ),
                    ],
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

          const SizedBox(height: 20),

          // Developer Support & GitHub Open Source Section
          const DeveloperSupportSection(),

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

  Future<void> _handleBackupFlow(BuildContext context) async {
    NativeApiChannel.triggerNativeHaptic();
    final menuProv = context.read<MenuProvider>();
    final tableProv = context.read<TableProvider>();
    final orderProv = context.read<OrderProvider>();
    final posProv = context.read<PosProvider>();

    final shouldBackup = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CulinaryColors.flameOrange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_rounded, color: CulinaryColors.flameOrange, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Backup Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following data will be saved to your RestPos backup file:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            _buildBackupItemRow(Icons.restaurant_rounded, 'Dishes', '${menuProv.items.length} items'),
            _buildBackupItemRow(Icons.category_rounded, 'Categories', '${menuProv.categories.length} categories'),
            _buildBackupItemRow(Icons.table_restaurant_rounded, 'Tables', '${tableProv.tables.length} tables'),
            _buildBackupItemRow(Icons.receipt_long_rounded, 'Orders & Bills', '${orderProv.orders.length} orders'),
            _buildBackupItemRow(Icons.storefront_rounded, 'Restaurant', posProv.profile.name),
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saved to Download/RestPos folder. Overwrites previous backup and stays safe if app is uninstalled.',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CulinaryColors.flameOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Save Backup'),
          ),
        ],
      ),
    );

    if (shouldBackup == true && context.mounted) {
      try {
        final file = await BackupRestoreService.exportBackup(
          profile: posProv.profile,
          categories: menuProv.categories,
          items: menuProv.items,
          tables: tableProv.tables,
          orders: orderProv.orders,
        );

        // Native Android Notification
        await NativeApiChannel.showNotification(
          title: 'RestPos Backup Successful',
          message: 'Saved to ${file.path} (${menuProv.items.length} dishes, ${orderProv.orders.length} orders)',
        );

        if (context.mounted) {
          AppNotification.showSuccess(
            context,
            'Saved to ${file.path}',
            title: 'Backup Successful',
            duration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(
            context,
            'Backup failed: $e',
            title: 'Backup Error',
          );
        }
      }
    }
  }

  Future<void> _handleRestoreFlow(BuildContext context) async {
    NativeApiChannel.triggerNativeHaptic();

    // 1. Fetch existing backup metadata
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final info = await BackupRestoreService.getExistingBackupInfo();

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    if (info == null) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.search_off_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('No Backup Found'),
              ],
            ),
            content: const Text(
              'No previous backup file (restpos_backup.json) was found in Download/RestPos. Please perform a backup first.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
      return;
    }

    // 2. Show detailed restore inspection dialog with File Size, Timestamp & Contents
    if (context.mounted) {
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CulinaryColors.royalBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_backup_restore_rounded, color: CulinaryColors.royalBlue, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Restore from Backup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Backup details found on device:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              _buildBackupItemRow(Icons.event_rounded, 'Backup Date', info.formattedDate),
              _buildBackupItemRow(Icons.data_usage_rounded, 'File Size', info.formattedSize),
              _buildBackupItemRow(Icons.storefront_rounded, 'Restaurant', info.restaurantName),
              _buildBackupItemRow(Icons.restaurant_rounded, 'Dishes', '${info.dishCount} items'),
              _buildBackupItemRow(Icons.category_rounded, 'Categories', '${info.categoryCount} categories'),
              _buildBackupItemRow(Icons.table_restaurant_rounded, 'Tables', '${info.tableCount} tables'),
              _buildBackupItemRow(Icons.receipt_long_rounded, 'Orders & Bills', '${info.orderCount} orders'),
              const Divider(height: 18),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Restoring will replace current menu and orders with this backup data. Continue?',
                        style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CulinaryColors.flameOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Restore'),
            ),
          ],
        ),
      );

      if (shouldRestore == true && context.mounted) {
        final menuProv = context.read<MenuProvider>();
        final tableProv = context.read<TableProvider>();
        final orderProv = context.read<OrderProvider>();
        final posProv = context.read<PosProvider>();

        final backup = info.data;
        posProv.updateProfile(backup.profile);
        menuProv.setCategories(backup.categories);
        menuProv.replaceAllItems(backup.items);
        tableProv.replaceAllTables(backup.tables);
        orderProv.replaceAllOrders(backup.orders);

        AppNotification.showSuccess(
          context,
          'Restored ${backup.items.length} dishes, ${backup.tables.length} tables, and ${backup.orders.length} orders!',
          title: 'Restore Completed',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Widget _buildBackupItemRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: CulinaryColors.flameOrange),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}
