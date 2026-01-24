import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/models/auth/auth_state.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/widgets/floow_logo.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // Controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Role Selection State
  String selectedRole = 'WORKER';
  final List<String> roles = ['WORKER', 'CLIENT', 'COMPANY', 'ADMIN'];

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the auth state for loading indicators
    final AuthState authState = ref.watch(authNotifierProvider);

    // 2. Listen for errors or status changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
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

      // Note: Success redirection is handled automatically by the GoRouter
      // redirect logic in app_router.dart (status == authenticated -> dashboard)
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO ---
                const FloowLogo(
                  isAppBar: false,
                  textColor: Colors.black,
                  iconSize: 40,
                  fontSize: 28,
                ),
                const SizedBox(height: 30),

                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // --- FORM FIELDS ---
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),

                // --- ROLE SELECTOR ---
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: "Role",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          if (value != null)
                            setState(() => selectedRole = value);
                        },
                ),

                const SizedBox(height: 24),

                // --- SIGNUP BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            // Basic Validation
                            if (usernameController.text.isEmpty ||
                                passwordController.text.isEmpty ||
                                emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please fill all fields"),
                                ),
                              );
                              return;
                            }

                            // Trigger Signup
                            ref
                                .read(authNotifierProvider.notifier)
                                .signup(
                                  usernameController.text,
                                  emailController.text,
                                  passwordController.text,
                                  selectedRole,
                                );
                          },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Signup"),
                  ),
                ),

                // --- LOGIN LINK ---
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navigate back to Login
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
