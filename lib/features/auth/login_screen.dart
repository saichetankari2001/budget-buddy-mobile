import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'signup_screen.dart';

String _authErrorMessage(Object? error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
  }
  return 'Something went wrong — try again.';
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
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
                  : () => ref.read(authStateProvider.notifier).login(
                        _emailController.text,
                        _passwordController.text,
                      ),
              child: authState.isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Log in'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              ),
              child: const Text('No account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
