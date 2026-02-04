import 'dart:math';
import 'dart:ui'; // Required for PointMode

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/models/auth/auth_state.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/widgets/floow_logo.dart';

class NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fixed seed to keep the noise static (doesn't dance around)
    final random = Random(42);

    final paint = Paint()
      ..color = Colors.white
          .withOpacity(0.12) // Slightly more visible
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round; // Round dots look better for noise

    // SIGNIFICANTLY INCREASED DENSITY
    // Changed 0.05 to 0.80. This creates thousands more dots.
    final int count = (size.width * size.height * 0.25).toInt();

    final List<Offset> points = [];

    for (int i = 0; i < count; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      points.add(Offset(x, y));
    }

    // Draw all points in one batch for performance
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TechnicalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white
          .withOpacity(0.25) // INCREASED: Was 0.1. Now much more visible.
      ..strokeWidth = 1.0;

    final plusPaint = Paint()
      ..color = Colors.white
          .withOpacity(0.6) // INCREASED: Was 0.3. Now pops more.
      ..strokeWidth = 1.5; // INCREASED: Made slightly thicker (was 1.2)

    const double step = 35.0;
    final random = Random(42);

    // Draw the main grid lines
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw the markers
    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        if (random.nextDouble() < 0.15) {
          const double length = 10.0;

          // Horizontal
          canvas.drawLine(
            Offset(x - length, y),
            Offset(x + length, y),
            plusPaint,
          );
          // Vertical
          canvas.drawLine(
            Offset(x, y - length),
            Offset(x, y + length),
            plusPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
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
    final isLoading = authState.status == AuthStatus.loading;
    final screenHeight = MediaQuery.of(context).size.height;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ---------------------------------------------
            // LAYER 1: The Complex Background Stack
            // ---------------------------------------------
            // ---------------------------------------------
            // LAYER 1: The Complex Background Stack
            // ---------------------------------------------
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. The Base Gradient (Light Top -> Dark Bottom)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2C2C2C), // Lighter Charcoal (Upper Side)
                          Color(0xFF000000), // Pure Black (Lower Side)
                        ],
                        // Stops control where the fade happens
                        stops: [0.0, 0.8],
                      ),
                    ),
                  ),

                  // 2. The Noise Texture
                  // It sits ON TOP of the gradient, but BEHIND the grid lines
                  CustomPaint(painter: NoisePainter(), size: Size.infinite),

                  // 3. Extra Shadow Gradient at the very bottom
                  // This ensures the bottom area is pitch black before the white sheet starts
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 150, // The height of the bottom shadow area
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(
                              0.9,
                            ), // Deep shadow at bottom
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. The Grid Lines
                  // Placed LAST so they remain sharp and "untouched" by the noise or shadows
                  CustomPaint(
                    painter: TechnicalGridPainter(),
                    size: Size.infinite,
                  ),

                  // 5. White transition (Optional: keeps the blend into the white sheet smooth)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(
                              0.05,
                            ), // Very subtle transition
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- LAYER 2: Logo ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.25,
              child: const Center(
                child: FloowLogo(
                  textColor: Colors.white,
                  iconSize: 50,
                  fontSize: 32,
                  isAppBar: false,
                ),
              ),
            ),

            // --- LAYER 3: White Bottom Sheet ---
            Positioned(
              top: screenHeight * 0.22,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "Enter your valid email address and password to access your account.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildInputLabel("Email Address"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: usernameController,
                        enabled: !isLoading,
                        decoration: _buildInputDecoration(
                          hint: "username@email.com",
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildInputLabel("Password"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        enabled: !isLoading,
                        decoration: _buildInputDecoration(
                          hint: "************",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildPrimaryButton(
                        label: "Log in",
                        isLoading: isLoading,
                        onPressed: () => ref
                            .read(authNotifierProvider.notifier)
                            .login(
                              usernameController.text,
                              passwordController.text,
                            ),
                      ),

                      const SizedBox(height: 16),

                      _buildSocialButton(
                        label: "Sign in with Google",
                        iconPath: 'assets/images/google_logo.svg',
                        onPressed: isLoading ? null : () {},
                      ),

                      const SizedBox(height: 24),
                      const _OrDivider(),
                      const SizedBox(height: 24),

                      _buildSecondaryButton(
                        label: "Create an account",
                        onPressed: () => context.push('/signup'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.all(16),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String iconPath,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF3F4F6),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ensure you have the SVG asset, otherwise use an Icon placeholder
            SvgPicture.asset(iconPath, height: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Or", style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}
