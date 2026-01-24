import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:mobile_frontend/models/auth/auth_state.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/widgets/floow_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 1. Explicitly cast the watch to AuthState
    final AuthState authState = ref.watch(authNotifierProvider);

    // 2. Add <AuthState> to ref.listen to fix the "Object" error
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      // Now 'next' is correctly recognized as AuthState
      if (next.status == AuthStatus.unauthenticated &&
          next.errorMessage != null) {
        if (next.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      // ... (Rest of your UI code remains exactly the same)
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FloowLogo(
                  isAppBar: false,
                  textColor: Colors.black,
                  iconSize: 50,
                  fontSize: 32,
                ),
                const SizedBox(height: 40),
                Text("Login", style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 24),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            ref
                                .read(authNotifierProvider.notifier)
                                .login(
                                  usernameController.text,
                                  passwordController.text,
                                );
                          },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login"),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
