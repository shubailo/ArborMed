import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';
import '../widgets/password_strength_meter.dart';

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
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final auth = GetIt.I<AuthContract>();
        await auth.register(
           _emailController.text.trim(),
           _passwordController.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your email.')),
        );
        
        final email = _emailController.text.trim();
        context.push('/verify?email=$email');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Failed: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: CozyTheme.of(context).accent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Hero(
                  tag: 'auth_icon',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.paperWhite,
                      shape: BoxShape.circle,
                      boxShadow: theme.shadowSmall,
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 60,
                      color: theme.primary,
                    ),
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
                const SizedBox(height: 48),
                ArborCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: CozyTheme.inputDecoration(context, 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: theme.textPrimary),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Email is required';
                            if (!_emailRegex.hasMatch(val)) return 'Please enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: CozyTheme.inputDecoration(context, 'Medical Handle (@username)'),
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: theme.textPrimary),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _displayNameController,
                          decoration: CozyTheme.inputDecoration(context, 'Full Professional Name'),
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: theme.textPrimary),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: CozyTheme.inputDecoration(context, 'Password').copyWith(
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: theme.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(color: theme.textPrimary),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (val.length < 8) return 'Min 8 characters';
                            if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Missing uppercase';
                            if (!RegExp(r'[0-9]').hasMatch(val)) return 'Missing number';
                            if (!RegExp(r'[\W\_]').hasMatch(val)) return 'Missing special char';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        PasswordStrengthMeter(password: _passwordController.text),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _submit,
                                  child: const Text('Create Account'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.pop(),
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: "Login",
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
}

class ArborCard extends StatelessWidget {
  final Widget child;
  const ArborCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: theme.shadowSmall,
      ),
      child: child,
    );
  }
}
