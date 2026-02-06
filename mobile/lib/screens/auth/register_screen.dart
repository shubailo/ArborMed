import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';

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

  final _emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");

  void _submitStep1() async {
    if (_formKey.currentState!.validate()) {
       try {
        await Provider.of<AuthProvider>(context, listen: false).apiService.post('/auth/register', {
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
          const SnackBar(content: Text('Verification code sent to your email.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: ${e.toString().replaceAll('Exception:', '').trim()}')),
        );
      }
    }
  }

  void _submitStep2() async {
    if (_otpController.text.length < 6) return;
    
    try {
      await Provider.of<AuthProvider>(context, listen: false).verifyEmail(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification successful! You can now log in.')),
      );
      Navigator.pop(context); // Return to login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification Failed: ${e.toString().replaceAll('Exception:', '').trim()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(_isStep2 ? 'Verify Email' : 'Join ArborMed')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (!_isStep2) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'john@example.com'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email is required';
                      if (!_emailRegex.hasMatch(val)) return 'Please enter a valid email address';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Medical Handle (@username)', hintText: 'jdoe001'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: 'Display Name', hintText: 'John Doe'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (val) => val == null || val.length < 4 ? 'Too short (min 4 chars)' : null,
                  ),
                ] else ...[
                  Text(
                    'We sent a 6-digit code to ${_emailController.text}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: '6-Digit Verification Code',
                      hintText: '123456',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                isLoading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _isStep2 ? _submitStep2 : _submitStep1,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(_isStep2 ? 'Verify & Continue' : 'Create Account'),
                    ),
                if (_isStep2) 
                   TextButton(
                    onPressed: () => setState(() => _isStep2 = false),
                    child: const Text('Change Email / Edit Details'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
