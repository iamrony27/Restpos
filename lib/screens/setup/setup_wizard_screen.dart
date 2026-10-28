import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/animations/smooth_page_route.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/theme/color_schemes.dart';
import '../../core/utils/app_notification.dart';
import '../../providers/menu_provider.dart';
import '../../providers/pos_provider.dart';
import '../../widgets/dietary_badge.dart';
import '../../widgets/developer_support_section.dart';
import '../home_shell_screen.dart';

class SetupWizardScreen extends StatefulWidget {
  final bool isInitialSetup;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const SetupWizardScreen({
    super.key,
    this.isInitialSetup = false,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Restaurant Info
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _legalNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  // Step 2: Tax & Compliance
  late bool _isGstEnabled;
  late double _gstRatePercent;
  late bool _isTaxInclusive;
  late final TextEditingController _gstinController;
  late final TextEditingController _fssaiController;

  // Step 3: Billing & Payments
  late bool _isRoundOffEnabled;
  late final TextEditingController _upiIdController;

  // Step 4: Menu Categories & Dishes Selection
  final Set<int> _selectedCategoryIds = {};
  final Set<int> _selectedItemIds = {};
  int _activeCategoryFilterId = 0;

  @override
  void initState() {
    super.initState();
    final pos = Provider.of<PosProvider>(context, listen: false);
    final menu = Provider.of<MenuProvider>(context, listen: false);
    final p = pos.profile;

    _nameController = TextEditingController(text: p.isSetupCompleted ? p.name : '');
    _taglineController = TextEditingController(text: p.isSetupCompleted ? p.tagline : '');
    _legalNameController = TextEditingController(text: p.isSetupCompleted ? p.legalName : '');
    _phoneController = TextEditingController(text: p.isSetupCompleted ? p.phone : '');
    _emailController = TextEditingController(text: p.isSetupCompleted ? p.email : '');
    _addressController = TextEditingController(text: p.isSetupCompleted ? p.address : '');

    _isGstEnabled = p.isGstEnabled;
    _gstRatePercent = p.gstRatePercent;
    _isTaxInclusive = p.isSetupCompleted ? p.isTaxInclusive : true;
    _gstinController = TextEditingController(text: p.isSetupCompleted ? p.gstin : '');
    _fssaiController = TextEditingController(text: p.isSetupCompleted ? p.fssai : '');

    _isRoundOffEnabled = p.isRoundOffEnabled;
    _upiIdController = TextEditingController(text: p.isSetupCompleted ? p.upiId : '');

    // Initialize all existing categories and items as selected by default
    _selectedCategoryIds.addAll(menu.categories.map((c) => c.id));
    _selectedItemIds.addAll(menu.items.where((i) => i.isAvailable).map((i) => i.id));
    if (menu.categories.isNotEmpty) {
      _activeCategoryFilterId = menu.categories.first.id;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _taglineController.dispose();
    _legalNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _fssaiController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _nextStep() {
    NativeApiChannel.triggerNativeHaptic();
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep += 1);
    } else {
      _finishSetup();
    }
  }

  void _prevStep() {
    NativeApiChannel.triggerNativeHaptic();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _skipSetup() async {
    NativeApiChannel.triggerNativeHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_setup_completed', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      SmoothPageRoute(
        page: HomeShellScreen(
          onToggleTheme: widget.onToggleTheme ?? () {},
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  Future<void> _finishSetup() async {
    NativeApiChannel.triggerNativeHaptic();
    final pos = Provider.of<PosProvider>(context, listen: false);
    final menu = Provider.of<MenuProvider>(context, listen: false);

    // Apply category & item selections
    for (final item in menu.items) {
      final shouldBeAvailable = _selectedItemIds.contains(item.id) &&
          _selectedCategoryIds.contains(item.categoryId);
      menu.setItemAvailability(item.id, shouldBeAvailable);
    }

    final updatedProfile = pos.profile.copyWith(
      name: _nameController.text.trim().isEmpty ? 'Rest POS' : _nameController.text.trim(),
      tagline: _taglineController.text.trim(),
      legalName: _legalNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      isGstEnabled: _isGstEnabled,
      gstRatePercent: _gstRatePercent,
      defaultTaxBps: (_gstRatePercent * 100).round(),
      isTaxInclusive: _isTaxInclusive,
      gstin: _gstinController.text.trim(),
      fssai: _fssaiController.text.trim(),
      isRoundOffEnabled: _isRoundOffEnabled,
      upiId: _upiIdController.text.trim(),
      isSetupCompleted: true,
    );

    pos.updateProfile(updatedProfile);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_setup_completed', true);

    if (!mounted) return;

    AppNotification.showSuccess(
      context,
      'Restaurant Setup Saved Successfully!',
      title: 'Setup Complete 🎉',
    );

    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacement(
        SmoothPageRoute(
          page: HomeShellScreen(
            onToggleTheme: widget.onToggleTheme ?? () {},
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isInitialSetup ? 'Welcome to Rest POS' : 'Restaurant Setup Wizard',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.isInitialSetup,
        actions: [
          if (widget.isInitialSetup)
            TextButton(
              onPressed: _skipSetup,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper Indicator Header (5 Steps)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Profile', Icons.storefront_rounded),
                  _buildStepDivider(0),
                  _buildStepIndicator(1, 'Tax/FSSAI', Icons.receipt_long_rounded),
                  _buildStepDivider(1),
                  _buildStepIndicator(2, 'Billing', Icons.account_balance_wallet_rounded),
                  _buildStepDivider(2),
                  _buildStepIndicator(3, 'Menu', Icons.restaurant_menu_rounded),
                  _buildStepDivider(3),
                  _buildStepIndicator(4, 'Review', Icons.task_alt_rounded),
                ],
              ),
            ),

            // Page View (5 Pages)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Profile(theme),
                  _buildStep2TaxAndFssai(theme),
                  _buildStep3Billing(theme),
                  _buildStep4MenuSelection(theme),
                  _buildStep5Review(theme),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: BouncingButton(
                      onPressed: _nextStep,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [CulinaryColors.tandoorOrange, CulinaryColors.flameOrange],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: CulinaryColors.tandoorOrange.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _currentStep == 4 ? 'Save & Start Billing 🚀' : 'Continue Step ${_currentStep + 2} →',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, IconData icon) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    Color bg;
    Color fg;
    if (isActive) {
      bg = CulinaryColors.tandoorOrange;
      fg = Colors.white;
    } else if (isDone) {
      bg = CulinaryColors.emeraldGreen;
      fg = Colors.white;
    } else {
      bg = Colors.grey.withOpacity(0.2);
      fg = Colors.grey;
    }

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: CulinaryColors.tandoorOrange.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : icon,
            color: fg,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? CulinaryColors.tandoorOrange : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int stepIndex) {
    final isDone = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isDone ? CulinaryColors.emeraldGreen : Colors.grey.withOpacity(0.3),
      ),
    );
  }

  // STEP 1: Restaurant Profile Info
  Widget _buildStep1Profile(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CulinaryColors.tandoorOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.storefront_rounded, color: CulinaryColors.tandoorOrange, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Basic Restaurant Profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Details printed on KOT and customer receipts', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Restaurant Display Name *',
            hintText: 'e.g. Spice Garden Restaurant',
            prefixIcon: const Icon(Icons.restaurant_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _taglineController,
          decoration: InputDecoration(
            labelText: 'Tagline / Cuisine Subtitle',
            hintText: 'e.g. Authentic Tandoor & Dining',
            prefixIcon: const Icon(Icons.format_quote_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _legalNameController,
          decoration: InputDecoration(
            labelText: 'Legal Entity Name',
            hintText: 'e.g. Spice Garden Hospitality Pvt Ltd',
            prefixIcon: const Icon(Icons.business_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Contact Phone Number',
            hintText: 'e.g. +91 98765 43210',
            prefixIcon: const Icon(Icons.phone_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'e.g. contact@spicegarden.in',
            prefixIcon: const Icon(Icons.email_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Full Address',
            hintText: 'e.g. 123 MG Road, Bengaluru, Karnataka 560001',
            prefixIcon: const Icon(Icons.location_on_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // STEP 2: Tax (GST) & FSSAI Compliance
  Widget _buildStep2TaxAndFssai(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CulinaryColors.turmericGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_user_rounded, color: CulinaryColors.turmericGold, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GST & FSSAI Compliance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Legal tax breakdown and food safety registration', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // GST Toggle Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isGstEnabled ? CulinaryColors.emeraldGreen.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          color: _isGstEnabled ? CulinaryColors.emeraldGreen.withOpacity(0.05) : theme.colorScheme.surface,
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
                        color: _isGstEnabled ? CulinaryColors.emeraldGreen.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.percent_rounded,
                        color: _isGstEnabled ? CulinaryColors.emeraldGreen : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enable GST Billing',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            _isGstEnabled
                                ? 'GST will be itemized (CGST + SGST split) on customer invoices'
                                : 'Non-GST / Tax-Exempt Mode: 0% tax applied to orders',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isGstEnabled,
                      activeColor: CulinaryColors.emeraldGreen,
                      onChanged: (val) {
                        setState(() => _isGstEnabled = val);
                      },
                    ),
                  ],
                ),

                if (_isGstEnabled) ...[
                  const Divider(height: 24),
                  const Text('Select Standard GST Rate:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [5.0, 12.0, 18.0].map((rate) {
                      final selected = _gstRatePercent == rate;
                      return ChoiceChip(
                        label: Text(
                          '$rate% ${rate == 5.0 ? "(Restaurant Std)" : ""}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: selected,
                        selectedColor: CulinaryColors.emeraldGreen,
                        onSelected: (val) {
                          if (val) setState(() => _gstRatePercent = rate);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _gstinController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'GSTIN Number (15 Digits)',
                      hintText: 'e.g. 29ABCDE1234F1Z5',
                      prefixIcon: const Icon(Icons.badge_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tax Mode: Inclusive vs Exclusive
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tax Calculation Mode',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isTaxInclusive
                              ? 'Inclusive: Menu prices already include GST (MRP style). No extra tax added at checkout.'
                              : 'Exclusive: GST is added on top of menu prices at checkout.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<bool>(
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                          segments: const [
                            ButtonSegment(
                              value: true,
                              icon: Icon(Icons.check_circle_outline_rounded, size: 16),
                              label: Text('Tax Inclusive'),
                            ),
                            ButtonSegment(
                              value: false,
                              icon: Icon(Icons.add_circle_outline_rounded, size: 16),
                              label: Text('Tax Exclusive'),
                            ),
                          ],
                          selected: {_isTaxInclusive},
                          onSelectionChanged: (set) {
                            setState(() => _isTaxInclusive = set.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // FSSAI License Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blueGrey.withOpacity(0.3), width: 1.5),
          ),
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
                        color: CulinaryColors.royalBlue.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: CulinaryColors.royalBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FSSAI Food Safety License',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            'Mandatory 14-digit food safety registration displayed on every bill',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _fssaiController,
                  keyboardType: TextInputType.number,
                  maxLength: 14,
                  decoration: InputDecoration(
                    labelText: 'FSSAI License Number (14 Digits)',
                    hintText: 'e.g. 11223344556677',
                    prefixIcon: const Icon(Icons.verified_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 3: Billing & Payments (Round-Off & UPI)
  Widget _buildStep3Billing(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CulinaryColors.amethystViolet.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: CulinaryColors.amethystViolet, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Billing & Payment Rules', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Round-off adjustments and instant UPI payments', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Round Off Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isRoundOffEnabled ? CulinaryColors.amethystViolet.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          color: _isRoundOffEnabled ? CulinaryColors.amethystViolet.withOpacity(0.05) : theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isRoundOffEnabled ? CulinaryColors.amethystViolet.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.currency_rupee_rounded,
                    color: _isRoundOffEnabled ? CulinaryColors.amethystViolet : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invoice Total Round-Off',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        _isRoundOffEnabled
                            ? 'Automatically rounds final payable bill to the nearest Rupee (± paise)'
                            : 'Exact paise billing (e.g. ₹324.45)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isRoundOffEnabled,
                  activeColor: CulinaryColors.amethystViolet,
                  onChanged: (val) {
                    setState(() => _isRoundOffEnabled = val);
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Dynamic UPI VPA
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blueGrey.withOpacity(0.3), width: 1.5),
          ),
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
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, color: CulinaryColors.flameOrange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Merchant UPI ID (VPA)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            'Generates dynamic instant payment QR codes on cashier screen',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _upiIdController,
                  decoration: InputDecoration(
                    labelText: 'UPI VPA Address',
                    hintText: 'e.g. spicegarden@icici or 9876543210@paytm',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 4: Menu Categories & Dishes Selection
  Widget _buildStep4MenuSelection(ThemeData theme) {
    final menu = Provider.of<MenuProvider>(context);

    final filteredDishes = menu.items.where((i) {
      if (_activeCategoryFilterId == 0) return true;
      return i.categoryId == _activeCategoryFilterId;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
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
                    child: const Icon(Icons.restaurant_menu_rounded, color: CulinaryColors.flameOrange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Choose Categories & Dishes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        Text('Select what categories and items to enable initially', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Categories Filter & Toggle Chips
              const Text('Active Categories:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('All (${menu.categories.length})'),
                        selected: _activeCategoryFilterId == 0,
                        onSelected: (val) {
                          setState(() => _activeCategoryFilterId = 0);
                        },
                      ),
                    ),
                    ...menu.categories.map((c) {
                      final isCategoryEnabled = _selectedCategoryIds.contains(c.id);
                      final isFiltering = _activeCategoryFilterId == c.id;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(
                            isCategoryEnabled ? Icons.check_circle_rounded : Icons.cancel_outlined,
                            size: 16,
                            color: isCategoryEnabled ? CulinaryColors.emeraldGreen : Colors.grey,
                          ),
                          label: Text(c.name),
                          selected: isFiltering,
                          selectedColor: theme.colorScheme.primary.withOpacity(0.15),
                          onSelected: (val) {
                            setState(() => _activeCategoryFilterId = c.id);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              // Category master enable/disable switch
              if (_activeCategoryFilterId != 0) ...[
                Builder(
                  builder: (ctx) {
                    final currentCat = menu.categories.where((c) => c.id == _activeCategoryFilterId).firstOrNull;
                    if (currentCat == null) return const SizedBox.shrink();
                    final isCatEnabled = _selectedCategoryIds.contains(currentCat.id);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCatEnabled ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Enable "${currentCat.name}" Category',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isCatEnabled ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                          Switch.adaptive(
                            value: isCatEnabled,
                            activeColor: CulinaryColors.emeraldGreen,
                            onChanged: (val) {
                              setState(() {
                                if (val) {
                                  _selectedCategoryIds.add(currentCat.id);
                                } else {
                                  _selectedCategoryIds.remove(currentCat.id);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),

        // Dishes List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filteredDishes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dish = filteredDishes[index];
              final isItemSelected = _selectedItemIds.contains(dish.id);
              final isParentCategoryEnabled = _selectedCategoryIds.contains(dish.categoryId);

              return CheckboxListTile(
                value: isItemSelected && isParentCategoryEnabled,
                enabled: isParentCategoryEnabled,
                activeColor: CulinaryColors.emeraldGreen,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                secondary: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: dish.imageUri != null
                      ? Image.asset(
                          dish.imageUri!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant_rounded),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant_rounded),
                        ),
                ),
                title: Row(
                  children: [
                    DietaryBadge(type: dish.dietaryType, size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dish.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isParentCategoryEnabled ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${dish.formattedPrice} • ${dish.sku ?? ""}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                onChanged: isParentCategoryEnabled
                    ? (val) {
                        setState(() {
                          if (val == true) {
                            _selectedItemIds.add(dish.id);
                          } else {
                            _selectedItemIds.remove(dish.id);
                          }
                        });
                      }
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  // STEP 5: Review & Confirm
  Widget _buildStep5Review(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CulinaryColors.tandoorOrange, CulinaryColors.flameOrange],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: CulinaryColors.tandoorOrange.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.celebration_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 10),
              const Text(
                'Setup Complete!',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Review your restaurant configuration below before launching.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildReviewRow('Restaurant Name', _nameController.text.trim().isEmpty ? 'Rest POS' : _nameController.text.trim()),
                _buildReviewRow('Tagline', _taglineController.text),
                _buildReviewRow('GST Status', _isGstEnabled ? 'Enabled (${_gstRatePercent.toStringAsFixed(0)}%)' : 'Disabled (Non-GST)'),
                if (_isGstEnabled) ...[
                  _buildReviewRow('GSTIN', _gstinController.text),
                  _buildReviewRow('Tax Mode', _isTaxInclusive ? 'Inclusive of Tax' : 'Exclusive (Added to bill)'),
                ],
                _buildReviewRow('FSSAI Number', _fssaiController.text.isEmpty ? 'Not Provided' : _fssaiController.text),
                _buildReviewRow('Round Off', _isRoundOffEnabled ? 'Enabled (Nearest ₹)' : 'Disabled'),
                _buildReviewRow('UPI VPA', _upiIdController.text),
                _buildReviewRow('Active Categories', '${_selectedCategoryIds.length} Categories Selected'),
                _buildReviewRow('Active Dishes', '${_selectedItemIds.length} Dishes Enabled'),
                _buildReviewRow('Contact Phone', _phoneController.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const DeveloperSupportSection(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
