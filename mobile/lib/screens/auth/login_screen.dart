import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_provider.dart';
import '../../theme/cozy_theme.dart';
import 'register_screen.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); 
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _identifierController.text.trim(),
          _passwordController.text,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: CozyTheme.accent,
          ),
        );
      }
    }
  }

  void _handleGoogleSignIn() async {
    try {
      final res = await Provider.of<AuthProvider>(context, listen: false).signInWithGoogle();
      if (res != null && res['isNewUser'] == true) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(
              email: res['email'],
              googleId: res['googleId'],
              suggestedDisplayName: res['suggestedDisplayName'],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In Failed: ${e.toString()}'),
          backgroundColor: CozyTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor: CozyTheme.background,
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: CozyTheme.shadowSmall,
                  ),
                  child: const Icon(Icons.medication_rounded, size: 60, color: CozyTheme.primary),
                ),
                const SizedBox(height: 16),
                Text('MedBuddy', style: CozyTheme.textTheme.displayLarge),
                Text('Professional Medical Learning', style: CozyTheme.textTheme.bodyMedium),
                const SizedBox(height: 48),

                // 📝 Login Card
                Card(
                  elevation: 0,
                  color: CozyTheme.paperWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _identifierController,
                            decoration: CozyTheme.inputDecoration('Email or Username'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: CozyTheme.inputDecoration('Password'),
                            obscureText: true,
                            validator: (val) => val == null || val.length < 4 ? 'Too short' : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text('Forgot Password?', style: TextStyle(color: CozyTheme.textSecondary)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _submit,
                                    child: const Text('Login', style: TextStyle(fontSize: 18)),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('OR', style: TextStyle(color: Colors.grey)),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _handleGoogleSignIn,
                              icon: const FaIcon(FontAwesomeIcons.google, size: 20, color: Color(0xFFDB4437)),
                              label: const Text('Sign in with Google', style: TextStyle(color: CozyTheme.textPrimary, fontSize: 16)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: CozyTheme.textTheme.bodyMedium,
                      children: const [
                        TextSpan(
                          text: "Create One",
                          style: TextStyle(fontWeight: FontWeight.bold, color: CozyTheme.primary),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final auth = Provider.of<AuthProvider>(context);
          
          return AlertDialog(
            backgroundColor: CozyTheme.paperWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isOTPSent ? 'Reset Password' : 'Forgot Password', style: CozyTheme.dialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOTPSent) ...[
                  const Text('Enter your email to receive a 6-digit reset code.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: CozyTheme.inputDecoration('Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ] else ...[
                  Text('Code sent to ${emailController.text}'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: otpController,
                    decoration: CozyTheme.inputDecoration('6-digit OTP'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPassController,
                    decoration: CozyTheme.inputDecoration('New Password'),
                    obscureText: true,
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
                onPressed: auth.isLoading ? null : () async {
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
                          const SnackBar(content: Text('Password reset successful! Please login.')),
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
        }
      ),
    );
  }
}
