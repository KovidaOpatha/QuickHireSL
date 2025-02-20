import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/applications_screen.dart';
import 'screens/chooserole_screen.dart';
import 'screens/studentregistration_screen.dart';
import 'screens/jobownerregistration_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF98C9C5),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/chooserole': (context) => const ChooseRoleScreen(
              email: '', // These will be passed via arguments
              password: '',
            ),
        '/studentregistration': (context) => const StudentRegistrationScreen(
              email: '', // These will be passed via arguments
              password: '',
            ),
        '/jobownerregistration': (context) => const JobOwnerRegistrationScreen(
              email: '', // These will be passed via arguments
              password: '',
            ),
        '/home': (context) => const HomeScreen(),
        '/applications': (context) => const ApplicationsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle any undefined routes here
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
    );
  }
}
