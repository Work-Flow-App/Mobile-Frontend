import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/controllers/auth/auth_controller.dart';
import 'package:mobile_frontend/widgets/floow_logo.dart';
import 'signup_screen.dart';
import '../dashboard/responsive_dashboard.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- CENTERED LOGO ---
                const FloowLogo(
                  isAppBar: false,
                  textColor: Colors.black, // Dark text for white background
                  iconSize: 50, // Larger icon
                  fontSize: 32, // Larger text
                ),
                const SizedBox(height: 40),

                Text("Login", style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 24),

                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            setState(() => loading = true);
                            try {
                              final response = await ref.read(
                                authControllerProvider({
                                  "type": "login",
                                  "username": usernameController.text,
                                  "password": passwordController.text,
                                }),
                              );

                              if (response.accessToken.isNotEmpty) {
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ResponsiveDashboard(),
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response.errorMessage),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Login failed: $e")),
                                );
                              }
                            }
                            setState(() => loading = false);
                          },
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login"),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
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
