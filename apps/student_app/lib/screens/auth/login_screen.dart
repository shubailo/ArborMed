import 'package:flutter/material.dart';
import 'auth_strings.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../theme/cozy_theme.dart';
import 'register_screen.dart';

import 'verification_screen.dart';
import '../../core/api_exceptions.dart';

class LoginScreen extends StatefulWidget {
  final String? initialIdentifier;
  const LoginScreen({super.key, this.initialIdentifier});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialIdentifier != null &&
        widget.initialIdentifier!.isNotEmpty) {
      _identifierController.text = widget.initialIdentifier!;
    }
  }

  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  bool _submitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    try {
      try {
        await auth.login(identifier, password);
      } on EmailVerificationRequired catch (challenge) {
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
        final verified =
            await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => VerificationScreen(
              email: challenge.email, verificationId: challenge.verificationId),
        ));
        if (mounted &&
            verified == true &&
            ModalRoute.of(context)?.isCurrent == true) {
          await auth.login(identifier, password);
        }
      }
    } catch (e) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final displayMsg = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(displayMsg),
        backgroundColor: CozyTheme.of(context, listen: false).accent,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        Provider.of<AuthProvider>(context).isLoading || _submitting;

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
                  context.authStrings.authLearn,
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
                              context.authStrings.authIdentifier,
                            ),
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              color: CozyTheme.of(context).textPrimary,
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? context.authStrings.authRequired
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
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
                                  color: CozyTheme.of(
                                    context,
                                  ).textSecondary,
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
                            style: TextStyle(
                              color: CozyTheme.of(context).textPrimary,
                            ),
                            validator: (val) => val == null || val.length < 4
                                ? context.authStrings.authShort
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  isLoading ? null : _showForgotPasswordDialog,
                              child: Text(
                                context.authStrings.authForgotLink,
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
                                    child: Text(
                                      context.authStrings.authLogin,
                                      style: const TextStyle(fontSize: 18),
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
                  onPressed: isLoading
                      ? null
                      : () async {
                          final returnedEmail = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                          if (mounted &&
                              returnedEmail != null &&
                              returnedEmail.isNotEmpty) {
                            setState(() {
                              _identifierController.text = returnedEmail;
                            });
                          }
                        },
                  child: RichText(
                    text: TextSpan(
                      text: context.authStrings.authNoAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: context.authStrings.authCreateLink,
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

  void _showForgotPasswordDialog() => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ResetPasswordDialog(),
      );
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog();
  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  String? _sentTo;
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final auth = context.read<AuthProvider>();
    final email = _sentTo ?? _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = context.authStrings.authEmailPrompt);
      return;
    }
    if (_sentTo != null && !RegExp(r'^\d{6}$').hasMatch(_otp.text.trim())) {
      setState(() => _error = context.authStrings.authCodePrompt);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_sentTo == null) {
        await auth.requestOTP(email);
        if (mounted) setState(() => _sentTo = email);
      } else {
        await auth.resetPassword(email, _otp.text.trim(), _password.text);
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
        final messenger = ScaffoldMessenger.of(context);
        final success = context.authStrings.authResetSuccess;
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ApiException
            ? error.message
            : context.authStrings.authTryAgain);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        backgroundColor: CozyTheme.of(context, listen: false).paperWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            _sentTo == null
                ? context.authStrings.authForgot
                : context.authStrings.authResetTitle,
            style: CozyTheme.of(context, listen: false).dialogTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_sentTo == null) ...[
            Text(context.authStrings.authResetHelp),
            const SizedBox(height: 16),
            TextFormField(
                controller: _email,
                enabled: !_busy,
                decoration: CozyTheme.inputDecoration(
                    context, context.authStrings.authEmail),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done),
          ] else ...[
            Text(context.authStrings.authCodeSent(_sentTo!)),
            const SizedBox(height: 16),
            TextFormField(
                controller: _otp,
                enabled: !_busy,
                decoration: CozyTheme.inputDecoration(
                    context, context.authStrings.authOtp),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next),
            const SizedBox(height: 16),
            TextFormField(
                controller: _password,
                enabled: !_busy,
                decoration: CozyTheme.inputDecoration(
                        context, context.authStrings.newPassword)
                    .copyWith(
                        suffixIcon: IconButton(
                            tooltip: _obscure
                                ? context.authStrings.authShowNew
                                : context.authStrings.authHideNew,
                            icon: Icon(_obscure
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure))),
                obscureText: _obscure,
                textInputAction: TextInputAction.done),
          ],
          if (_error != null)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator()),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.authStrings.cancel)),
          ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(_sentTo == null
                  ? context.authStrings.authSendCode
                  : context.authStrings.authReset)),
        ],
      );
}
