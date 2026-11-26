import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_exceptions.dart';
import '../../generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/cozy_theme.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String? registrationId;
  final String? verificationId;

  const VerificationScreen({
    super.key,
    required this.email,
    this.registrationId,
    this.verificationId,
  }) : assert((registrationId == null) != (verificationId == null));

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  bool get _current => mounted && ModalRoute.of(context)?.isCurrent == true;
  bool get _valid => RegExp(r'^\d{6}$').hasMatch(_otpController.text);
  AppLocalizations get _strings =>
      AppLocalizations.of(context) ??
      lookupAppLocalizations(const Locale('en'));

  void _show(String message, {bool restart = false}) {
    if (!_current) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      action: restart
          ? SnackBarAction(
              label: _strings.verificationRestart,
              onPressed: () {
                if (_current) Navigator.of(context).maybePop();
              })
          : null,
    ));
  }

  void _showFailure(Object error) {
    if (!_current) return;
    final strings = _strings;
    final status = error is ApiException ? error.statusCode : 0;
    final message = switch (status) {
      409 => strings.verificationChanged,
      429 => strings.verificationWait,
      503 => strings.verificationUnavailable,
      _ => error is ApiException ? error.message : strings.verificationRetry,
    };
    _show(message, restart: status == 409);
  }

  Future<void> _signOut() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().logout();
      if (mounted && _current) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      if (_current) _show(_strings.verificationSignOutFailed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_isLoading || !_valid) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final id = widget.registrationId;
      if (id == null) {
        await auth.verifyEmail(widget.email, _otpController.text.trim(),
            verificationId: widget.verificationId!);
      } else {
        await auth.verifyRegistration(
            widget.email, _otpController.text.trim(), id);
      }

      if (!mounted || !_current) return;
      _show(_strings.verificationSuccess);

      if (id == null) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      _showFailure(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final id = widget.registrationId;
      if (id == null) {
        await auth.requestOTP(widget.email,
            purpose: 'email-verification',
            verificationId: widget.verificationId!);
      } else {
        await auth.resendRegistrationOTP(widget.email, id);
      }

      if (_current) _show(_strings.verificationResent);
    } catch (error) {
      _showFailure(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final strings = _strings;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(strings.verifyEmailTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mark_email_read_rounded,
                      size: 80,
                      color: palette.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.verificationRequired,
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.verificationSentTo(widget.email),
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _otpController,
                      decoration: CozyTheme.inputDecoration(
                        context,
                        strings.verificationEnterCode,
                      ),
                      enabled: !_isLoading,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofillHints: const [AutofillHints.oneTimeCode],
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _verify(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLength: 6,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _valid ? _verify : null,
                              child: Text(
                                strings.verificationContinue,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading ? null : _resendOtp,
                      child: Text(
                        strings.verificationResend,
                        style: TextStyle(
                          color: palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextButton(
                      onPressed: _isLoading ? null : _signOut,
                      child: Text(
                        strings.signOut,
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ),
                  ],
                ))),
      ),
    );
  }
}
