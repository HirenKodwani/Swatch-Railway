import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:crm_train/main.dart' as app;

void main() {
  // Initialize the integration test binding.
  // This enables Espresso idling resources on Android.
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Note: enableEspressoIdlingResources was removed in newer integration_test
  // binding.enableEspressoIdlingResources = true;

  testWidgets('Full functional smoke test', (WidgetTester tester) async {
    // Launch the app
    app.main();

    // Wait for the app to load and settle (splash screen, etc.)
    await tester.pumpAndSettle();

    // Verify that the app is running.
    // Since we start with SplashScreen, we can check for its presence
    // or wait for it to transition to the next screen if it's quick.
    // For now, let's just ensure the app builds and shows some text.
    
    // Note: You can add more specific assertions here based on your UI.
    // expect(find.text('Welcome'), findsOneWidget);
  });
}
