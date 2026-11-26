import 'package:flutter/material.dart';
import 'auth_strings.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/cozy_theme.dart';
import '../../widgets/auth/password_strength_meter.dart';
import '../../core/api_exceptions.dart';
import 'verification_screen.dart';

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

  Future<void> _submitRegister() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      final registrationId = await context.read<AuthProvider>().register(
            email,
            _passwordController.text,
            username: _usernameController.text.trim(),
            displayName: _displayNameController.text.trim(),
          );
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) =>
            VerificationScreen(email: email, registrationId: registrationId),
      ));
    } catch (e) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final errorMsg = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception:', '').trim();

      // If user already exists, offer a smooth path to login
      if (errorMsg.toLowerCase().contains('already exists')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            action: SnackBarAction(
                label: context.authStrings.authLogin,
                onPressed: () {
                  if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                    Navigator.pop(context, email);
                  }
                }),
            backgroundColor: CozyTheme.of(context, listen: false).primary,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.authStrings.authRegFailed(errorMsg)),
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
                  context.authStrings.authJoin,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  context.authStrings.authJourney,
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
                            enabled: !_isSubmitting,
                            decoration: CozyTheme.inputDecoration(
                              context,
                              context.authStrings.authEmail,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: palette.textPrimary),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return context.authStrings.authEmailRequired;
                              }
                              if (!_emailRegex.hasMatch(val.trim())) {
                                return context.authStrings.authEmailInvalid;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            enabled: !_isSubmitting,
                            decoration: CozyTheme.inputDecoration(
                              context,
                              context.authStrings.authHandle,
                            ),
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: palette.textPrimary),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? context.authStrings.authUserRequired
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _displayNameController,
                            enabled: !_isSubmitting,
                            decoration: CozyTheme.inputDecoration(
                              context,
                              context.authStrings.authDisplayName,
                            ),
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: palette.textPrimary),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? context.authStrings.authDisplayRequired
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isSubmitting,
                            decoration: CozyTheme.inputDecoration(
                              context,
                              context.authStrings.authPassword,
                            ).copyWith(
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? context.authStrings.authShow
                                    : context.authStrings.authHide,
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
                                return context.authStrings.authPasswordRequired;
                              }
                              if (val.length < 8) {
                                return context.authStrings.authMinLength;
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(val)) {
                                return context.authStrings.authUpper;
                              }
                              if (!RegExp(r'[0-9]').hasMatch(val)) {
                                return context.authStrings.authNumber;
                              }
                              if (!RegExp(r'[\W\_]').hasMatch(val)) {
                                return context.authStrings.authSpecial;
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
                                    child: Text(context.authStrings.authCreate),
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
                      text: context.authStrings.authExisting,
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: context.authStrings.authLogin,
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
