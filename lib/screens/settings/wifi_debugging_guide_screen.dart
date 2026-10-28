import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/utils/app_notification.dart';

class WifiDebuggingGuideScreen extends StatelessWidget {
  const WifiDebuggingGuideScreen({super.key});

  void _copyCommand(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppNotification.showSuccess(
      context,
      'Copied "$label" to clipboard!',
      title: 'Copied to Clipboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Debugging & Live UI Preview'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.tertiaryContainer.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_tethering_rounded, size: 36, color: Color(0xFF0284C7)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Mobile Preview',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View and test changes on your phone in real time with sub-second hot reload over Wi-Fi.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            '3-Step Setup Instructions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          // Step 1
          _buildStepCard(
            context,
            stepNumber: '1',
            title: 'Enable Wireless Debugging on Phone',
            description:
                'Go to Phone Settings -> Developer Options -> Toggle "Wireless debugging" ON. Ensure your phone and PC are connected to the SAME Wi-Fi network.',
            action: BouncingButton(
              onPressed: () => NativeApiChannel.openWifiSettings(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Open Wi-Fi Settings',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Step 2
          _buildStepCard(
            context,
            stepNumber: '2',
            title: 'Pair & Connect via ADB',
            description:
                'Tap on "Pair device with pairing code" on your phone to get IP and 6-digit code. Then run in your terminal:',
            command: 'adb pair 192.168.0.XXX:PORT\n# Enter the 6-digit code displayed on phone\nadb connect 192.168.0.XXX:PORT',
          ),

          const SizedBox(height: 14),

          // Step 3
          _buildStepCard(
            context,
            stepNumber: '3',
            title: 'Run with Instant Hot Reload',
            description:
                'Run the app from your project directory. Every time you save code, press "r" to hot reload within 0.5s!',
            command: 'cd "/media/NVME/aplication/restaurant POS/flutter_restaurant_pos"\nflutter run',
          ),

          const SizedBox(height: 24),

          // Host machine info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.computer_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('Developer Host IP', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Host Machine IP: 192.168.0.187\nEnsure your phone is on the 192.168.0.x subnet.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
    String? command,
    Widget? action,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    stepNumber,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: 12),
              action,
            ],
            if (command != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        command,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () => _copyCommand(context, command, title),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
