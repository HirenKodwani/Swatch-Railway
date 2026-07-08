// This is a widget test for Swachh Railways app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:crm_train/main.dart';
import 'package:crm_train/providers/auth_provider.dart';

void main() {
  testWidgets('Splash screen text validation and transition to LoginScreen', (WidgetTester tester) async {
    // Mock shared preferences before the provider loads the session
    SharedPreferences.setMockInitialValues({});
    
    final authProvider = AuthProvider();
    await authProvider.loadUserSession();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the splash screen title and subtitle are present initially
    expect(find.text("Swachh Railways"), findsOneWidget);
    expect(find.text("Swachh Bharat, Swachh Railways"), findsOneWidget);

    // Pump the 2 second delay timer and settle the routing transition
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify that we transitioned to the LoginScreen
    expect(find.text("Welcome Back"), findsOneWidget);
    expect(find.text("Choose your login method"), findsOneWidget);
  });
}


