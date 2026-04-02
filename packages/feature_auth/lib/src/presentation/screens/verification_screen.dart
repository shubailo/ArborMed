import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core_interop/core_interop.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  void _verify() async {
    if (_otpController.text.length < 6) return;

    setState(() => _isLoading = true);
    try {
      final auth = GetIt.I<AuthContract>();
      await auth.verifyEmail(widget.email, _otpController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully!')),
      );

      // Shell will handle navigation based on authenticated state
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification Failed: ${e.toString().replaceAll('Exception:', '').trim()}',
          ),
          backgroundColor: CozyTheme.of(context).accent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      final auth = GetIt.I<AuthContract>();
      await auth.requestOTP(widget.email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read_rounded,
              size: 80,
              color: palette.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Verification Required',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a 6-digit verification code to:\n${widget.email}',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 48),
            TextFormField(
              controller: _otpController,
              decoration:
                  CozyTheme.inputDecoration(context, 'Enter 6-digit code'),
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
                      onPressed: _verify,
                      child: const Text('Verify & Continue',
                          style: TextStyle(fontSize: 18)),
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : _resendOtp,
              child: Text(
                'Resend Code',
                style: TextStyle(
                    color: palette.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 48),
            TextButton(
              onPressed: () {
                GetIt.I<AuthContract>().logout();
              },
              child: Text('Sign out',
                  style: TextStyle(color: palette.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
