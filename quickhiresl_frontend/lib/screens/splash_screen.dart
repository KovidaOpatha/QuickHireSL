import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Fade-in Animation (logo appears slowly)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _navigateToLogin();
  }

  // Auto-Navigate to Login after 5 seconds
  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    _goToLogin();
  }

  // Function to navigate to Login Screen
  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      body: GestureDetector(
        onTap: _goToLogin, // Tap anywhere to go to Login
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Image.asset(
              'assets/quickhire_logo.png',
              width: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 50, color: Colors.red);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
