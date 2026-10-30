import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/cozy_theme.dart';
import '../../widgets/auth/password_strength_meter.dart';
import '../../core/api_exceptions.dart';

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
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).apiService.post('/auth/register', {
        'email': _emailController.text.trim(),
        'username': _usernameController.text.trim(),
        'display_name': _displayNameController.text.trim(),
        'password': _passwordController.text,
      });

      if (!mounted) return;

      if (res is Map && res['token'] != null) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAuthDataFromResponse(res.cast<String, dynamic>());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration successful! Welcome to ArborMed!'),
            backgroundColor: CozyTheme.of(context, listen: false).primary,
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception:', '').trim();

      // If user already exists, offer a smooth path to login
      if (errorMsg.toLowerCase().contains('already exists')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: CozyTheme.of(context, listen: false).primary,
          ),
        );
        Navigator.pop(context, _emailController.text.trim());
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: $errorMsg'),
          backgroundColor: CozyTheme.of(context, listen: false).accent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // 🩺 Header Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.paperWhite,
                    shape: BoxShape.circle,
                    boxShadow: palette.shadowSmall,
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 60,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Join ArborMed',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  'Start your medical journey',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),

                // 📝 Registration Card
                Card(
                  elevation: 0,
                  color: palette.paperWhite,
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
                            controller: _emailController,
                            decoration: CozyTheme.inputDecoration(
                              context,
                              'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: palette.textPrimary),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!_emailRegex.hasMatch(val.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            decoration: CozyTheme.inputDecoration(
                              context,
                              'Medical Handle (@username)',
                            ),
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: palette.textPrimary),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Username is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _displayNameController,
                            decoration: CozyTheme.inputDecoration(
                              context,
                              'Display Name',
                            ),
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: palette.textPrimary),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Display name is required'
                                : null,
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
                                  color: palette.textSecondary,
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
                            onFieldSubmitted: (_) => _submitRegister(),
                            style: TextStyle(color: palette.textPrimary),
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              if (val.length < 8) {
                                return 'Min 8 characters';
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(val)) {
                                return 'Missing uppercase letter';
                              }
                              if (!RegExp(r'[0-9]').hasMatch(val)) {
                                return 'Missing number';
                              }
                              if (!RegExp(r'[\W\_]').hasMatch(val)) {
                                return 'Missing special character';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          PasswordStrengthMeter(
                            password: _passwordController.text,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: _isSubmitting
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton(
                                    onPressed: _submitRegister,
                                    style: ElevatedButton.styleFrom(
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: const Text('Create Account'),
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
                    Navigator.pop(context);
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
                            color: palette.primary,
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
}
