import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

// The main entry point of the application. 
// It wraps the MyApp widget with ProviderScope to enable 
// Riverpod state management throughout the app.
