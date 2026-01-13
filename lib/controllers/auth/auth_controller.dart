import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/auth/auth_model.dart';
import 'package:mobile_frontend/providers/auth/auth_provider.dart';

// Family provider: accepts a Map<String,String> for login/signup
final authControllerProvider =
    Provider.family<Future<AuthResponse>, Map<String, String>>((
      ref,
      data,
    ) async {
      final authService = ref.read(authProvider);

      final type = data['type'] ?? 'login';

      if (type == 'login') {
        final username = data['username']!;
        final password = data['password']!;
        return authService.login(username, password);
      } else if (type == 'signup') {
        final username = data['username']!;
        final email = data['email']!;
        final password = data['password']!;
        return authService.signup(username, email, password);
      }

      throw Exception("Invalid type: $type");
    });
