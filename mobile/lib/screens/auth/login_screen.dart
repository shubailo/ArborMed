import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); // Email or Username
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _identifierController.text.trim(),
          _passwordController.text,
        );
        // Navigation is handled in main.dart via auth state
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('MedBuddy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                  hintText: 'e.g. jdoe001 or john@example.com',
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) => val!.length < 4 ? 'Too short' : null,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0)),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 20),
              isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Login'),
                  ),
              const Divider(),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text('Create Account'),
              ),
            ],
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final auth = Provider.of<AuthProvider>(context);
          
          return AlertDialog(
            title: Text(isOTPSent ? 'Reset Password' : 'Forgot Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOTPSent) ...[
                  const Text('Enter your email to receive a 6-digit reset code.'),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ] else ...[
                  Text('Code sent to ${emailController.text}'),
                  TextFormField(
                    controller: otpController,
                    decoration: const InputDecoration(labelText: '6-digit OTP'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: newPassController,
                    decoration: const InputDecoration(labelText: 'New Password'),
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
