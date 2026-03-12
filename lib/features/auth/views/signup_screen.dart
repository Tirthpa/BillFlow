import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/auth_repository.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  bool _isLoading = false;

  void _signup() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            businessName: _businessNameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            gstNumber: _gstController.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Business Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextField(
                controller: _businessNameController,
                decoration: const InputDecoration(hintText: 'Business Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(hintText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(hintText: 'Business Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _gstController,
                decoration: const InputDecoration(
                  hintText: 'GSTIN (Leave blank if not applicable)',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
