import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/ai_generation_screen.dart';
import 'screens/premium_subscription_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_dashboard_screen.dart';

import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web requires explicit FirebaseOptions; Android uses google-services.json
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDTYGOtXc0b-A_v4lHyehYz9hiOLP7IEHg',
        appId: '1:702175616724:android:b39c667ac9b17063ff6541',
        messagingSenderId: '702175616724',
        projectId: 'fitmeal-final',
        storageBucket: 'fitmeal-final.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  final userProvider = UserProvider();
  await userProvider.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const FitMealApp(),
    ),
  );
}

class FitMealApp extends StatelessWidget {
  const FitMealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitMeal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => HomeScreen(key: UniqueKey()),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/ai-generation': (context) => const AIGenerationScreen(),
        '/premium': (context) => const PremiumSubscriptionScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
