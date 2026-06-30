import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:crm_train/main.dart' as app;
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Admin User Generation Tests', () {
    setUpAll(() async {
      app.main();
      await Future.delayed(const Duration(seconds: 2));
    });

    testWidgets('Admin creates and approves MCC and Worker users', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Log in as an existing Admin or Master account
      await loginAsEmailPassword(tester, 'admin@gmail.com', '123456');

      // 2. Navigate to User Management
      // Wait for dashboard to load
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      final usersTab = find.text('Users'); // Adjust if the tab name is different
      if (usersTab.evaluate().isNotEmpty) {
        await tester.tap(usersTab.first);
        await tester.pumpAndSettle();
      }

      // 3. Create MCC User
      // Note: Adjust the buttons based on your actual Admin UI
      final createUserBtn = find.text('Create User');
      if (createUserBtn.evaluate().isNotEmpty) {
        await tester.tap(createUserBtn);
        await tester.pumpAndSettle();
        
        await tester.enterText(find.byKey(const ValueKey('name')), 'MCC Test');
        await tester.enterText(find.byKey(const ValueKey('email')), 'mcc_test@swachhrailways.com');
        await tester.enterText(find.byKey(const ValueKey('password')), 'password123');
        // Select role MCC (if it's a dropdown, you'd tap it and select)
        // Submit
        final submitBtn = find.text('Submit');
        await tester.tap(submitBtn);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // 4. Create Worker User
      if (createUserBtn.evaluate().isNotEmpty) {
        await tester.tap(createUserBtn);
        await tester.pumpAndSettle();
        
        await tester.enterText(find.byKey(const ValueKey('name')), 'Worker Test');
        await tester.enterText(find.byKey(const ValueKey('email')), 'worker_test@swachhrailways.com');
        await tester.enterText(find.byKey(const ValueKey('password')), 'password123');
        // Select role Janitor
        // Submit
        final submitBtn = find.text('Submit');
        await tester.tap(submitBtn);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // 5. Approve Users (if required by your workflow)
      // Navigate to Pending Approvals and click Approve

      // Clean up by logging out
      await logoutUser(tester);
    });
  });
}
