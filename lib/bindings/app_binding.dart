// lib/bindings/app_bindings.dart

import 'package:expo_project/controller/auth_controller.dart';
import 'package:expo_project/controller/home_controller.dart';
import 'package:expo_project/controller/splash_controller.dart';
import 'package:get/get.dart';

import '../controller/on_boarding_controller.dart';
import '../controller/stats_controller.dart';
import '../controller/transactions_list_controller.dart';
import '../controller/transaxtion_controller.dart';
// import any other controllers you have

class AppBindings implements Bindings {
  @override
  void dependencies() {
    // Instantiate your controllers here:
    Get.put(AddTransactionController());
    Get.put(TransactionListController());
    Get.put(StatsController());
    Get.put(AuthController());
    Get.put(HomeController());
    Get.put(SplashController());
    Get.put(OnboardingController());
    // …and any others, e.g.:
    // Get.put(UserController());
    // Get.put(CategoryController());
  }
}
