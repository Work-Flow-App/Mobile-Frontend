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

// 1. Add WidgetsBindingObserver to listen for background/foreground state changes
class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // 2. Create FocusNodes to track which field is currently active
  final usernameFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  // State for toggling password visibility
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Register the observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Unregister the observer and dispose of all controllers/nodes
    WidgetsBinding.instance.removeObserver(this);
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 3. Automatically show keyboard when the app resumes if a field is focused
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (usernameFocusNode.hasFocus || passwordFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    }
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
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
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
                                    focusNode:
                                        usernameFocusNode, // Pass FocusNode
                                    enabled: !isLoading,
                                  ),
                                  const SizedBox(height: 20),

                                  // Password Field with Toggle logic
                                  _buildTextField(
                                    label: "Password",
                                    hint: "••••••••••••",
                                    controller: passwordController,
                                    focusNode:
                                        passwordFocusNode, // Pass FocusNode
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
                                              // Dismiss keyboard on submit
                                              FocusScope.of(context).unfocus();

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
    required FocusNode focusNode, // 4. Require the FocusNode
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
          focusNode: focusNode, // Assign FocusNode
          enabled: enabled,
          obscureText: isPassword ? obscureText : false,
          style: const TextStyle(color: Colors.black),

          // 5. Unfocus when tapping anywhere outside the text field
          onTapOutside: (event) => FocusScope.of(context).unfocus(),

          // 6. Force the keyboard to show if the user taps a field that already has focus
          onTap: () {
            if (focusNode.hasFocus) {
              SystemChannels.textInput.invokeMethod('TextInput.show');
            }
          },

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
