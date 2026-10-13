import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';

String _authErrorMessage(Object? error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
  }
  return 'Something went wrong — try again.';
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (authState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _authErrorMessage(authState.error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () => ref.read(authStateProvider.notifier).signup(
                        _emailController.text,
                        _passwordController.text,
                      ),
              child: authState.isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign up'),
            ),
            if (Navigator.of(context).canPop())
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Already have an account? Log in'),
              ),
          ],
        ),
      ),
    );
  }
}
