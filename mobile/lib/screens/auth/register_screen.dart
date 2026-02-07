import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/cozy_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isStep2 = false; // Whether we are in OTP stage

  final _emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");

  void _submitStep1() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .apiService
            .post('/auth/register', {
          'email': _emailController.text.trim(),
          'username': _usernameController.text.trim(),
          'display_name': _displayNameController.text.trim(),
          'password': _passwordController.text,
        });

        setState(() {
          _isStep2 = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification code sent to your email.'),
            backgroundColor: CozyTheme.of(context, listen: false).primary,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Registration Failed: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: CozyTheme.of(context, listen: false).accent,
          ),
        );
      }
    }
  }

  void _submitStep2() async {
    if (_otpController.text.length < 6) return;

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .verifyRegistration(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification successful! Logging in...'),
          backgroundColor: CozyTheme.of(context, listen: false).primary,
        ),
      );
      // Navigate to Dashboard/Home and clear stack
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Verification Failed: ${e.toString().replaceAll('Exception:', '').trim()}'),
          backgroundColor: CozyTheme.of(context, listen: false).accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final palette = CozyTheme.of(context);

    return Scaffold(
      backgroundColor: palette.background,
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
                    color: palette.paperWhite,
                    shape: BoxShape.circle,
                    boxShadow: palette.shadowSmall,
                  ),
                  child: Icon(
                      _isStep2
                          ? Icons.mark_email_read_rounded
                          : Icons.person_add_rounded,
                      size: 60,
                      color: palette.primary),
                ),
                const SizedBox(height: 16),
                Text(_isStep2 ? 'Verify Email' : 'Join ArborMed',
                    style: Theme.of(context).textTheme.displayLarge),
                Text(
                    _isStep2
                        ? 'Enter the code sent to your email'
                        : 'Start your medical journey',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 48),

                // 📝 Registration Card
                Card(
                  elevation: 0,
                  color: palette.paperWhite,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isStep2) ...[
                            TextFormField(
                              controller: _emailController,
                              decoration:
                                  CozyTheme.inputDecoration(context, 'Email'),
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: palette.textPrimary),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!_emailRegex.hasMatch(val)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              decoration: CozyTheme.inputDecoration(
                                  context, 'Medical Handle (@username)'),
                              style: TextStyle(color: palette.textPrimary),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _displayNameController,
                              decoration: CozyTheme.inputDecoration(
                                  context, 'Display Name'),
                              style: TextStyle(color: palette.textPrimary),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: CozyTheme.inputDecoration(
                                  context, 'Password'),
                              obscureText: true,
                              style: TextStyle(color: palette.textPrimary),
                              validator: (val) => val == null || val.length < 4
                                  ? 'Too short (min 4 chars)'
                                  : null,
                            ),
                          ] else ...[
                            Text(
                              _emailController.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _otpController,
                              decoration: CozyTheme.inputDecoration(
                                  context, '6-Digit Code'),
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                  fontSize: 24,
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary),
                              textAlign: TextAlign.center,
                              maxLength: 6,
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed:
                                        _isStep2 ? _submitStep2 : _submitStep1,
                                    style: ElevatedButton.styleFrom(
                                      textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    child: Text(_isStep2
                                        ? 'Verify & Continue'
                                        : 'Create Account'),
                                  ),
                          ),
                          if (_isStep2)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => _isStep2 = false),
                                child: Text('Change Email / Edit Details',
                                    style: TextStyle(
                                        color: palette.textSecondary)),
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
                    Navigator.pop(context); // Go back to Login
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: palette.primary),
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
}
