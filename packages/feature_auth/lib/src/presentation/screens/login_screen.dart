import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:get_it/get_it.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = GetIt.I<AuthService>();
      await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
        role: widget.role,
      );
      // Navigation is handled by the Shell observing the authStateStream
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
          title: Text(
              '${widget.role[0].toUpperCase()}${widget.role.substring(1)} Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ArborCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: CozyTheme.inputDecoration(context, 'Email'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration:
                            CozyTheme.inputDecoration(context, 'Password')
                                .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onLogin(),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ArborButton(
                          text: 'Login',
                          onPressed: _isLoading ? null : _onLogin,
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
    );
  }
}

// Minimal placeholder for the legacy ArborCard if not in core yet
class ArborCard extends StatelessWidget {
  final Widget child;
  const ArborCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.paperWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: theme.shadowSmall,
      ),
      child: child,
    );
  }
}
