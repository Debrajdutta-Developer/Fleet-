import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'auth_providers.dart';

/// Form login and registration screen utilizing Clean Architecture components.
/// Supports Email/Password, Phone OTP, and Google Sign-in options.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Email controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Phone controllers
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // State configurations
  bool _isSignUp = false;
  bool _usePhoneAuth = false;
  bool _codeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = ref.read(authControllerProvider.notifier);
    bool success = false;

    if (_usePhoneAuth) {
      if (!_codeSent) {
        // Send SMS OTP code
        await authController.verifyPhoneNumber(
          phoneNumber: _phoneController.text.trim(),
          onCodeSent: (String verId) {
            setState(() {
              _verificationId = verId;
              _codeSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP code dispatched. Check your device.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
        return;
      } else {
        // Verify SMS OTP code
        success = await authController.signInWithPhoneNumber(
          verificationId: _verificationId!,
          smsCode: _otpController.text.trim(),
        );
      }
    } else {
      // Email/Password sign in or sign up
      if (_isSignUp) {
        success = await authController.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      } else {
        success = await authController.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    }

    if (success && mounted) {
      final user = ref.read(currentUserProvider);
      if (user?.companyId == null || user!.companyId!.isEmpty) {
        context.go('/company-setup');
      } else {
        context.go('/dashboard');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      final user = ref.read(currentUserProvider);
      if (user?.companyId == null || user!.companyId!.isEmpty) {
        context.go('/company-setup');
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authControllerProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 768;

    return Scaffold(
      body: Row(
        children: [
          // Desktop branding sidebar banner
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                color: colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'FleetOS ERP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'The unified command center for fleet logistics, multi-tenant inventory, routing metrics, and enterprise billing infrastructure.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Secured with AES 256-bit standards',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main Login Content Form
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small Mobile Logo Placeholder
                        if (!isDesktop) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping_rounded,
                                color: colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'FleetOS',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],

                        Text(
                          _usePhoneAuth
                              ? 'SMS OTP verification'
                              : (_isSignUp
                                  ? 'Create Corporate Account'
                                  : 'Welcome Operator'),
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _usePhoneAuth
                              ? 'Secure login via phone authentication.'
                              : (_isSignUp
                                  ? 'Get started with FleetOS ERP'
                                  : 'Log in to access your dashboard and fleet diagnostics.'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error Banner message box
                        if (authState.errorMessage != null) ...[
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
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: TextStyle(
                                      color: colorScheme.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Render Phone Form inputs
                        if (_usePhoneAuth) ...[
                          CustomTextField(
                            controller: _phoneController,
                            labelText: 'Phone Number',
                            hintText: '+15550199',
                            enabled: !_codeSent,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Phone number is required';
                              if (!val.startsWith('+'))
                                return 'Must include country code (e.g. +1)';
                              return null;
                            },
                          ),
                          if (_codeSent) ...[
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _otpController,
                              labelText: 'SMS Verification Code',
                              hintText: '123456',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.pin_outlined,
                              textInputAction: TextInputAction.done,
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Code is required';
                                if (val.length < 6)
                                  return 'Code must be 6 digits';
                                return null;
                              },
                            ),
                          ],
                        ]
                        // Render standard Email inputs
                        else ...[
                          if (_isSignUp) ...[
                            CustomTextField(
                              controller: _nameController,
                              labelText: 'Full Name',
                              hintText: 'John Doe',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          CustomTextField(
                            controller: _emailController,
                            labelText: 'Email Address',
                            hintText: 'operator@fleetos.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Email is required';
                              final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailReg.hasMatch(val))
                                return 'Invalid email format';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Password is required';
                              if (val.length < 6)
                                return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Action Submit Button
                        CustomButton(
                          text: _usePhoneAuth
                              ? (_codeSent ? 'VERIFY SMS OTP' : 'SEND OTP CODE')
                              : (_isSignUp
                                  ? 'REGISTER COMPANY ADMIN'
                                  : 'INITIALIZE HANDSHAKE'),
                          isLoading: authState.isLoading,
                          onPressed: _submitForm,
                        ),
                        const SizedBox(height: 20),

                        // Single Sign-on Section
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR SECURE SINGLE SIGN-ON',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onBackground.withOpacity(
                                    0.4,
                                  ),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Google Sign-In Button
                        CustomButton(
                          text: 'CONTINUE WITH GOOGLE',
                          type: ButtonType.secondary,
                          icon: Icons.account_circle_outlined,
                          isLoading: authState.isLoading,
                          onPressed: _handleGoogleSignIn,
                        ),
                        const SizedBox(height: 24),

                        // Auth Toggle Action Links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _usePhoneAuth = !_usePhoneAuth;
                                  _codeSent = false;
                                  _verificationId = null;
                                  _formKey.currentState?.reset();
                                });
                              },
                              child: Text(
                                _usePhoneAuth
                                    ? 'Verify via Email'
                                    : 'Verify via SMS OTP',
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                            if (!_usePhoneAuth)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _formKey.currentState?.reset();
                                  });
                                },
                                child: Text(
                                  _isSignUp ? 'Sign In' : 'Register Admin',
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
