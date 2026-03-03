import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../theme/cozy_theme.dart';
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
        await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).login(_identifierController.text.trim(), _passwordController.text);
      } catch (e) {
        if (!mounted) return;

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('email_not_verified')) {
          // 📧 Redirect to verification screen
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

    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🩺 Logo / Hero Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CozyTheme.of(context).paperWhite,
                    shape: BoxShape.circle,
                    boxShadow: CozyTheme.of(context).shadowSmall,
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    size: 60,
                    color: CozyTheme.of(context).primary,
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

                // 📝 Login Card
                Card(
                  elevation: 0,
                  color: CozyTheme.of(context).paperWhite,
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
                            style: TextStyle(
                              color: CozyTheme.of(context).textPrimary,
                            ),
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
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: CozyTheme.of(
                                    context,
                                  ).textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: TextStyle(
                              color: CozyTheme.of(context).textPrimary,
                            ),
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
                                style: TextStyle(
                                  color: CozyTheme.of(context).textSecondary,
                                ),
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
                            color: CozyTheme.of(context).primary,
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
    // Keep internal logic but wrap with CozyTheme's inputDecoration
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

          return AlertDialog(
            backgroundColor: CozyTheme.of(context, listen: false).paperWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isOTPSent ? 'Reset Password' : 'Forgot Password',
              style: CozyTheme.of(context, listen: false).dialogTitle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOTPSent) ...[
                  const Text(
                    'Enter your email to receive a 6-digit reset code.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: CozyTheme.inputDecoration(context, 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                  ),
                ] else ...[
                  Text('Code sent to ${emailController.text}'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: otpController,
                    decoration: CozyTheme.inputDecoration(
                      context,
                      '6-digit OTP',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPassController,
                    decoration: CozyTheme.inputDecoration(
                      context,
                      'New Password',
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: CozyTheme.of(context).textSecondary,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                        tooltip: obscureNewPassword
                            ? 'Show password'
                            : 'Hide password',
                      ),
                    ),
                    obscureText: obscureNewPassword,
                    textInputAction: TextInputAction.done,
                  ),
                ],
                if (auth.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
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
                                  content: Text(
                                    'Password reset successful! Please login.',
                                  ),
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
