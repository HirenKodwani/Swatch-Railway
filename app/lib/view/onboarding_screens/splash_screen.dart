import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../helper/helper.dart';
import '../../../providers/auth_provider.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.checkAndClearSessionIfNeeded();

    await authProvider.loadUserSession();

    await Future.delayed(const Duration(seconds: 2));

    if (authProvider.isLoggedIn) {
      try {
        final user = authProvider.currentUser;
        if (user != null) {
          navigateUser(context, user);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'app_logo',
              child: CircleAvatar(
                radius: 48,
                backgroundImage: AssetImage('assets/images/indian_railway.png'),
                backgroundColor: const Color(0xFF0B63FF).withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Swachh Railways",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1B2B),
              ),
            ),
            const Text(
              "Swachh Bharat, Swachh Railways",
              style: TextStyle(fontSize: 14, color: Color(0xFF0A1B2B)),
            ),
          ],
        ),
      ),
    );
  }
}
