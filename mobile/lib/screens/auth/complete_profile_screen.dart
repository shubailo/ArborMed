import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/cozy_theme.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String email;
  final String googleId;
  final String? suggestedDisplayName;

  const CompleteProfileScreen({
    super.key,
    required this.email,
    required this.googleId,
    this.suggestedDisplayName,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _displayNameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase()
    );
    _displayNameController = TextEditingController(text: widget.suggestedDisplayName ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).completeSocialProfile(
          email: widget.email,
          googleId: widget.googleId,
          username: _usernameController.text.trim(),
          displayName: _displayNameController.text.trim(),
        );
        if (mounted) {
           Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to complete profile: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    final palette = CozyTheme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: palette.background),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                color: palette.paperWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, size: 64, color: palette.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Almost There!',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your profile to join ArborMed',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _usernameController,
                          decoration: CozyTheme.inputDecoration(context, 'Username'),
                          validator: (val) => val == null || val.isEmpty ? 'Pick a username' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _displayNameController,
                          decoration: CozyTheme.inputDecoration(context, 'Display Name'),
                          validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: palette.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Start Playing', style: TextStyle(fontSize: 18)),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
