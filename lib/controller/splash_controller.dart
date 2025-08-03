// lib/controller/splash_controller.dart

import 'package:hisabi/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show splash for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // No one signed in → go to Register
      Get.offAllNamed(AppRoutes.signUp);
      return;
    }

    // Signed in → check if their profile doc exists
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (doc.exists) {
      final data = doc.data();
      final onboarded = data?['onboardingComplete'] == true;

      if (onboarded) {
        // Fully onboarded → into the main app
        Get.offAllNamed(AppRoutes.main);
      } else {
        // Profile exists but onboarding not finished → go through onboarding
        Get.offAllNamed(AppRoutes.onBoarding);
      }
    } else {
      // No user doc at all → treat as brand-new user
      Get.offAllNamed(AppRoutes.signUp);
    }
  }
}
