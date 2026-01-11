import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/services/auth/auth_service.dart';

// Riverpod provider for AuthService
final authProvider = Provider<AuthService>((ref) => AuthService());
