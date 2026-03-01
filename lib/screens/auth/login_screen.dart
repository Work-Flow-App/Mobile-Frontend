import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/auth/auth_state.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/widgets/brand_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // State for toggling password visibility
  bool _obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authNotifierProvider);

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
    });

    final isLoading = authState.status == AuthStatus.loading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        // Set the background color to match the dark logo area
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          bottom: false, // Let the white sheet extend to the very bottom edge
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // --- Logo Area ---
                        // It will naturally take up the space it needs without overlapping
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 50.0),
                          child: const Center(
                            child: BrandLogo(
                              isAppBar: false,
                              iconSize: 65,
                              textSvgWidth: 250,
                              axis: Axis.vertical,
                            ),
                          ),
                        ),

                        // --- White "Sheet" Area ---
                        // Expanded ensures it pushes to the bottom of the screen
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(40),
                                topRight: Radius.circular(40),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 40,
                            ),
                            // Wrapping the form inside SafeArea so it respects bottom navigation bars
                            child: SafeArea(
                              top: false,
                              child: Column(
                                children: [
                                  const Text(
                                    "Welcome Back!",
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Enter your valid username and password\nto access your account.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 40),

                                  // Username Field
                                  _buildTextField(
                                    label: "Username",
                                    hint: "username",
                                    controller: usernameController,
                                    enabled: !isLoading,
                                  ),
                                  const SizedBox(height: 20),

                                  // Password Field with Toggle logic
                                  _buildTextField(
                                    label: "Password",
                                    hint: "••••••••••••",
                                    controller: passwordController,
                                    enabled: !isLoading,
                                    isPassword: true,
                                    obscureText: _obscurePassword,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 30),

                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              final cleanedUsername =
                                                  usernameController.text
                                                      .trim();
                                              ref
                                                  .read(
                                                    authNotifierProvider
                                                        .notifier,
                                                  )
                                                  .login(
                                                    cleanedUsername,
                                                    passwordController.text,
                                                  );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            Colors.grey.shade800,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              "Log in",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Reusable TextField helper
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool enabled = true,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: isPassword ? obscureText : false,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
