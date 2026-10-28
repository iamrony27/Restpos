import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/channels/native_api_channel.dart';
import '../core/theme/color_schemes.dart';
import '../core/utils/app_notification.dart';
import '../services/github_update_service.dart';

class DeveloperSupportSection extends StatefulWidget {
  final bool isCompact;

  const DeveloperSupportSection({
    super.key,
    this.isCompact = false,
  });

  @override
  State<DeveloperSupportSection> createState() => _DeveloperSupportSectionState();
}

class _DeveloperSupportSectionState extends State<DeveloperSupportSection> {
  static const String upiId = '7074018142@ptsbi';
  static const String whatsappNumber = '+917074018142';
  static const String githubRepoUrl = 'https://github.com/iamrony27/Restpos';

  bool _isCheckingUpdate = false;

  Future<void> _handleCheckForUpdate(BuildContext context) async {
    NativeApiChannel.triggerNativeHaptic();
    setState(() => _isCheckingUpdate = true);

    try {
      final info = await GitHubUpdateService.checkForUpdate();
      if (!context.mounted) return;

      setState(() => _isCheckingUpdate = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                info.isUpdateAvailable ? Icons.system_update_rounded : Icons.check_circle_rounded,
                color: info.isUpdateAvailable ? CulinaryColors.flameOrange : CulinaryColors.emeraldGreen,
              ),
              const SizedBox(width: 10),
              Text(
                info.isUpdateAvailable ? 'Update Available!' : 'Up to Date',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Installed Version:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(info.currentVersion, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GitHub Release:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(info.latestVersion, style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: info.isUpdateAvailable ? CulinaryColors.flameOrange : CulinaryColors.emeraldGreen,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                info.statusMessage,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('What\'s New:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      info.releaseNotes!,
                      style: TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CulinaryColors.flameOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.open_in_browser_rounded, size: 16),
              label: Text(info.isUpdateAvailable ? 'Download Update' : 'View on GitHub'),
              onPressed: () {
                Navigator.pop(ctx);
                NativeApiChannel.openUrl(info.downloadUrl ?? githubRepoUrl);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        setState(() => _isCheckingUpdate = false);
        AppNotification.showError(
          context,
          'Update check failed: $e',
          title: 'Update Check',
        );
      }
    }
  }

  void _handleStarRepo() {
    NativeApiChannel.triggerNativeHaptic();
    NativeApiChannel.openUrl(githubRepoUrl);
  }

  void _handleOpenWhatsApp() {
    NativeApiChannel.triggerNativeHaptic();
    final cleanPhone = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappUrl =
        'https://wa.me/$cleanPhone?text=Hello%20Rony%2C%20I%20am%20using%20Restpos%20and%20interested%20in%20custom%20development%20%2F%20support!';
    NativeApiChannel.openUrl(whatsappUrl);
  }

  void _handleCopyUpi(BuildContext context) {
    NativeApiChannel.triggerNativeHaptic();
    Clipboard.setData(const ClipboardData(text: upiId));
    AppNotification.showSuccess(
      context,
      'UPI ID copied: $upiId',
      title: 'Copied to Clipboard',
    );
  }

  void _handlePayUpiDirect() {
    NativeApiChannel.triggerNativeHaptic();
    const upiUri =
        'upi://pay?pa=$upiId&pn=Rony%20Developer&cu=INR&tn=Restpos%20Support%20Tip';
    NativeApiChannel.openUrl(upiUri);
  }

  void _showUpiQrModal(BuildContext context) {
    NativeApiChannel.triggerNativeHaptic();
    const upiUri =
        'upi://pay?pa=$upiId&pn=Rony%20Developer&cu=INR&tn=Restpos%20Support%20Tip';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Support the Vibe Coder ☕',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Scan with any UPI App (GPay, PhonePe, Paytm, BHIM)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: upiUri,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1C1816),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1C1816),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('UPI ID: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text(upiId, style: TextStyle(color: CulinaryColors.flameOrange, fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _handleCopyUpi(ctx),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CulinaryColors.flameOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                label: const Text('Open UPI App Directly', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _handlePayUpiDirect();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. GitHub Actions Card: Check for Update & Star on GitHub
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.code_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Restpos Open Source',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                Text(
                                  'GitHub: iamrony27/Restpos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Open Repository',
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      onPressed: _handleStarRepo,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.star_rounded, size: 18, color: Colors.black87),
                        label: const Text('Star on GitHub ⭐', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                        onPressed: _handleStarRepo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isCheckingUpdate
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.system_update_rounded, size: 18),
                        label: const Text('Check for Update', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        onPressed: _isCheckingUpdate ? null : () => _handleCheckForUpdate(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. Developer (Vibe Coder) Emotional Note & Support
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: CulinaryColors.flameOrange.withOpacity(0.35),
              width: 1.2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  CulinaryColors.flameOrange.withOpacity(0.06),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CulinaryColors.flameOrange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('☕', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A Note from the Vibe Coder 💖',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          Text(
                            'Crafted with passion by Rony (India)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hey there! 👋 I am a solo vibe coder who built RestPos from scratch to empower restaurants, cafes, and food business owners without paying heavy monthly SaaS subscriptions.\n\nEvery feature—from zero-lag touch billing to native thermal printing—was coded with love and late nights. If RestPos is helping your business grow and saving your hard-earned money, please consider supporting me with a small tip or coffee! Every contribution keeps this open-source project thriving!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 14),
                // UPI Support Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: CulinaryColors.flameOrange.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.currency_rupee_rounded, size: 18, color: CulinaryColors.flameOrange),
                                SizedBox(width: 6),
                                Text('UPI ID: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Flexible(
                                  child: Text(
                                    upiId,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                      color: CulinaryColors.flameOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Copy UPI ID',
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _handleCopyUpi(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CulinaryColors.flameOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.send_to_mobile_rounded, size: 16),
                              label: const Text('Tip via UPI App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: _handlePayUpiDirect,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                              label: const Text('Scan QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () => _showUpiQrModal(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 3. Custom App Development & WhatsApp Contact Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                        color: const Color(0xFF25D366).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone_android_rounded, color: Color(0xFF25D366), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customizable App for Any Client',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                          ),
                          Text(
                            'Tailor-made features for your restaurant',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Need custom POS branding, multi-branch syncing, cloud database, custom thermal invoice templates, or tailor-made apps for your restaurant / business? I build customized software for clients worldwide!',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4, fontSize: 12),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text(
                    'Contact Developer on WhatsApp (+91 7074018142)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                  onPressed: _handleOpenWhatsApp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
