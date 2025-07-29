import 'package:expo_project/main_page.dart';
import 'package:expo_project/view/auth/registration_page.dart';
import 'package:expo_project/view/auth/sign_in_screen.dart';
import 'package:expo_project/view/home/home_page.dart';
import 'package:expo_project/view/onBoarding/on_boarding_page.dart';
import 'package:expo_project/view/profile/profile_page.dart';
import 'package:expo_project/view/splash/splash_screen.dart';
import 'package:expo_project/view/transactions/add_transactions_page.dart';
import 'package:expo_project/view/tutorial/tutorial_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bindings/app_binding.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      initialBinding: AppBindings(),
      theme: ThemeData(
        textTheme: GoogleFonts.shareTechTextTheme(Theme.of(context).textTheme),
        useMaterial3: false,
      ),
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
        GetPage(name: AppRoutes.signUp, page: () => SignUpScreen()),
        GetPage(name: AppRoutes.register, page: () => RegistrationPage()),
        GetPage(name: AppRoutes.home, page: () => HomePage()),
        GetPage(name: AppRoutes.main, page: () => MainPage()),

        GetPage(name: AppRoutes.transactions, page: () => AddTransactionPage()),
        GetPage(name: AppRoutes.profile, page: () => ProfilePage()),
        GetPage(name: AppRoutes.tutorial, page: () => TutorialScreen()),
        GetPage(name: AppRoutes.onBoarding, page: () => OnboardingPage()),
      ],
    );
  }
}
