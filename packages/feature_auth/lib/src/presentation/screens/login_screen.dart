import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbormed_core/arbormed_core.dart';
import '../../application/auth_provider.dart';

import 'register_screen.dart';
import 'verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.login(
          _identifierController.text.trim(),
          _passwordController.text,
        );
      } catch (e) {
        if (!mounted) return;

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('email_not_verified')) {
          final email = _identifierController.text.trim();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => VerificationScreen(email: email)),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: CozyTheme.of(context, listen: false).accent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final theme = CozyTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.paperWhite,
                    shape: BoxShape.circle,
                    boxShadow: theme.shadowSmall,
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    size: 60,
                    color: theme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ArborMed',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  'Professional Medical Learning',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),
                Card(
                  elevation: 0,
                  color: theme.paperWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _identifierController,
                            decoration: CozyTheme.inputDecoration(
                              context,
                              'Email or Username',
                            ),
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: theme.textPrimary),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: CozyTheme.inputDecoration(
                              context,
                              'Password',
                            ).copyWith(
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: theme.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: TextStyle(color: theme.textPrimary),
                            validator: (val) => val == null || val.length < 4
                                ? 'Too short'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(color: theme.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton(
                                    onPressed: _submit,
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: "Create One",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    bool isOTPSent = false;
    bool obscureNewPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final auth = Provider.of<AuthProvider>(context);
          final theme = CozyTheme.of(context, listen: false);

          return AlertDialog(
            backgroundColor: theme.paperWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Reset Password', style: theme.dialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOTPSent) ...[
                  const Text('Enter your email to receive a reset code.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: CozyTheme.inputDecoration(context, 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ] else ...[
                  Text('Code sent to ${emailController.text}'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: otpController,
                    decoration: CozyTheme.inputDecoration(context, 'OTP'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPassController,
                    decoration: CozyTheme.inputDecoration(
                      context,
                      'New Password',
                    ).copyWith(
                      suffixIcon: IconButton(
                        tooltip: obscureNewPassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.textSecondary,
                        ),
                        onPressed: () => setModalState(
                          () => obscureNewPassword = !obscureNewPassword,
                        ),
                      ),
                    ),
                    obscureText: obscureNewPassword,
                  ),
                ],
                if (auth.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        try {
                          if (!isOTPSent) {
                            await auth.requestOTP(emailController.text.trim());
                            setModalState(() => isOTPSent = true);
                          } else {
                            await auth.resetPassword(
                              emailController.text.trim(),
                              otpController.text.trim(),
                              newPassController.text,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Success! Please login.'),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                child: Text(isOTPSent ? 'Reset' : 'Send Code'),
              ),
            ],
          );
        },
      ),
    );
  }
}
