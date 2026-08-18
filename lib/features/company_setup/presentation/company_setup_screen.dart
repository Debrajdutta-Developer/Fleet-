import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'company_providers.dart';

/// Onboarding screen allowing registered corporate admins to setup their tenants/companies.
class CompanySetupScreen extends ConsumerStatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profile Controllers
  final _nameController = TextEditingController(); // Company Name
  final _ownerNameController = TextEditingController(); // Owner Name

  // Financial Info Controllers
  final _gstNumberController = TextEditingController(); // GST Number (optional)
  final _panNumberController = TextEditingController(); // PAN Number (optional)

  // Contact Controllers
  final _phoneController = TextEditingController(); // Company Phone
  final _emailController = TextEditingController(); // Company Email
  final _addressController = TextEditingController(); // Company Address

  // Locale settings
  String _selectedCurrency = 'USD';
  String _selectedTimeZone = 'UTC';

  File? _logoFile;
  bool _mockLogoSelected = false;

  final List<String> _currencies = ['USD', 'INR', 'EUR', 'GBP', 'AED', 'SGD'];
  final List<String> _timeZones = [
    'UTC',
    'IST (UTC+5:30)',
    'EST (UTC-5)',
    'GMT (UTC+0)',
    'SGT (UTC+8)',
    'AEST (UTC+10)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _gstNumberController.dispose();
    _panNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickMockLogo() async {
    setState(() {
      _mockLogoSelected = true;
      _logoFile = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mock company logo profile selected successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final setupController = ref.read(companySetupControllerProvider.notifier);

    final success = await setupController.registerCompany(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      gstNumber: _gstNumberController.text.trim().isEmpty
          ? null
          : _gstNumberController.text.trim().toUpperCase(),
      panNumber: _panNumberController.text.trim().isEmpty
          ? null
          : _panNumberController.text.trim().toUpperCase(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      defaultCurrency: _selectedCurrency,
      timeZone: _selectedTimeZone,
      logoFile: _logoFile,
    );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(companySetupControllerProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 768;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Tenant Onboarding'),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
              ),
              elevation: isDesktop ? 2 : 0,
              color: isDesktop ? theme.cardTheme.color : Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 36.0 : 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Initialize Company Space',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a dedicated partition for your company, designate owners, configure tax mappings, contact details, and locale default variables.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onBackground.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Error message container
                      if (state.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.error.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Logo picker section
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickMockLogo,
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor:
                                    colorScheme.primary.withOpacity(0.08),
                                backgroundImage: _mockLogoSelected
                                    ? const NetworkImage(
                                        'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=200',
                                      )
                                    : null,
                                child: !_mockLogoSelected
                                    ? Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 32,
                                        color: colorScheme.primary,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Company Brand Logo',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Supports PNG, JPG (Max 5MB)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onBackground.withOpacity(
                                  0.4,
                                ),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 1: Corporate Profile
                      _buildSectionHeader(theme, 'Corporate Profile'),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Company Legal Name',
                        hintText: 'Globex Logistics Corp',
                        prefixIcon: Icons.business_outlined,
                        validator: (val) => val == null || val.isEmpty
                            ? 'Company name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _ownerNameController,
                        labelText: 'Owner / Legal Representative Name',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (val) => val == null || val.isEmpty
                            ? 'Owner name is required'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Contact Information
                      _buildSectionHeader(theme, 'Contact Information'),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        labelText: 'Company Phone Number',
                        hintText: '+1 (555) 0199',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: (val) => val == null || val.isEmpty
                            ? 'Company phone is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Company Email Address',
                        hintText: 'info@globexlogistics.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Company email is required';
                          final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailReg.hasMatch(val))
                            return 'Invalid email format';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _addressController,
                        labelText: 'Headquarters Address',
                        hintText: '100 Logistics Blvd, Suite 400',
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (val) => val == null || val.isEmpty
                            ? 'Address is required'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Section 3: Financial Mappings
                      _buildSectionHeader(
                        theme,
                        'Financial & Tax Registration',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _gstNumberController,
                              labelText: 'GSTIN Number (Optional)',
                              hintText: '29GGGGG1314R9Z6',
                              prefixIcon: Icons.receipt_long_outlined,
                              validator: (val) {
                                if (val != null && val.isNotEmpty) {
                                  if (val.length != 15) {
                                    return 'GST number must be 15 chars';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _panNumberController,
                              labelText: 'PAN Number (Optional)',
                              hintText: 'ABCDE1234F',
                              prefixIcon: Icons.credit_card_outlined,
                              validator: (val) {
                                if (val != null && val.isNotEmpty) {
                                  if (val.length != 10) {
                                    return 'PAN must be 10 chars';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 4: Localization Settings
                      _buildSectionHeader(
                        theme,
                        'Localization & Regional Defaults',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              decoration: InputDecoration(
                                labelText: 'Default Currency',
                                prefixIcon: Icon(
                                  Icons.monetization_on_outlined,
                                  size: 20,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              items: _currencies.map((String cur) {
                                return DropdownMenuItem<String>(
                                  value: cur,
                                  child: Text(cur),
                                );
                              }).toList(),
                              onChanged: (String? val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCurrency = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedTimeZone,
                              decoration: InputDecoration(
                                labelText: 'Time Zone',
                                prefixIcon: Icon(
                                  Icons.access_time_outlined,
                                  size: 20,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              items: _timeZones.map((String tz) {
                                return DropdownMenuItem<String>(
                                  value: tz,
                                  child: Text(tz),
                                );
                              }).toList(),
                              onChanged: (String? val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedTimeZone = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Actions
                      CustomButton(
                        text: 'CREATE TENANT PARTITION',
                        isLoading: state.isLoading,
                        onPressed: _submitForm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(),
      ],
    );
  }
}
