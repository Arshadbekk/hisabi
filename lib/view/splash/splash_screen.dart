// lib/modules/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller so its onReady() runs
    Get.put(SplashController());

    return Scaffold(
      backgroundColor: const Color(0xFFB7DAAE),
      body: Center(
        child: Image.asset(
          'assets/splash/splash.gif',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
