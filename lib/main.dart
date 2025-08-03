import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hisabi/main_page.dart';
import 'package:hisabi/models/txn.dart';
import 'package:hisabi/services/hive_services.dart';
import 'package:hisabi/view/auth/registration_page.dart';
import 'package:hisabi/view/auth/sign_in_screen.dart';
import 'package:hisabi/view/home/home_page.dart';
import 'package:hisabi/view/onBoarding/on_boarding_page.dart';
import 'package:hisabi/view/profile/profile_page.dart';
import 'package:hisabi/view/splash/splash_screen.dart';
import 'package:hisabi/view/transactions/add_transactions_page.dart';
import 'package:hisabi/view/tutorial/tutorial_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hisabi/view/splash/splash_screen.dart';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'bindings/app_binding.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
   // 1) Initialize Hive & Flutter bindings
  await Hive.initFlutter();
    Hive.registerAdapter(TxnAdapter());
  await HiveService.init();
    await GetStorage.init();           // ← initialize storage

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

     final pages = <GetPage>[
      GetPage(name: AppRoutes.splash,      page: () => const SplashScreen()),
      GetPage(name: AppRoutes.signUp,      page: () => SignUpScreen()),
      GetPage(name: AppRoutes.register,    page: () => RegistrationPage()),
      GetPage(name: AppRoutes.home,        page: () => HomePage()),
      GetPage(name: AppRoutes.main,        page: () => MainPage()),
      GetPage(name: AppRoutes.transactions,page: () => AddTransactionPage()),
      GetPage(name: AppRoutes.profile,     page: () => ProfilePage()),
      GetPage(name: AppRoutes.tutorial,    page: () => TutorialScreen()),
      GetPage(name: AppRoutes.onBoarding,  page: () => OnboardingPage()),
    ];

    // if (kIsWeb) {
    //   pages.addAll([
    //     GetPage(name: '/privacy', page: () => const PrivacyPage()),
    //     GetPage(name: '/terms',   page: () => const TermsPage()),
    //   ]);
    // }
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      initialBinding: AppBindings(),
      theme: ThemeData(
        textTheme: GoogleFonts.shareTechTextTheme(Theme.of(context).textTheme),
        useMaterial3: false,
      ),
      getPages: pages,
    );
  }
}
