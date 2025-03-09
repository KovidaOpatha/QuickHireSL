import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
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
import 'screens/applicant_details_screen.dart';
import 'screens/community_screen.dart';
import 'services/job_service.dart';
import 'services/messaging_service.dart';
import 'screens/conversations_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JobService()),
        ChangeNotifierProvider(create: (_) => MessagingService()),
      ],
      child: const MyApp(),
    ),
  );
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
              email: '',
              password: '',
            ),
        '/jobownerregistration': (context) => const JobOwnerRegistrationScreen(
              email: '',
              password: '',
            ),
        '/home': (context) => const HomeScreen(),
        '/applications': (context) => const ApplicationsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/community': (context) => CommunityScreen(),
        '/conversations': (context) => const ConversationsScreen(),
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
    );
  }
}