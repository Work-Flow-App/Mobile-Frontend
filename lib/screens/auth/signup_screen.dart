import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/controllers/auth/auth_controller.dart';
import 'package:mobile_frontend/widgets/floow_logo.dart';
import '../dashboard/responsive_dashboard.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Role State
  String selectedRole = 'WORKER';
  final List<String> roles = ['WORKER', 'CLIENT', 'COMPANY', 'ADMIN'];

  bool loading = false;

  @override
  Widget build(BuildContext context) {
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
                // --- CENTERED LOGO ---
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

                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
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
                  onChanged: (value) {
                    if (value != null) setState(() => selectedRole = value);
                  },
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
                                  "type": "signup",
                                  "username": usernameController.text,
                                  "email": emailController.text,
                                  "password": passwordController.text,
                                  "role": selectedRole, // Sending selected role
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
                                  SnackBar(content: Text("Signup failed: $e")),
                                );
                              }
                            }
                            setState(() => loading = false);
                          },
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Signup"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
