// lib/bindings/app_bindings.dart

import 'package:hisabi/controller/auth_controller.dart';
import 'package:hisabi/controller/home_controller.dart';
import 'package:hisabi/controller/splash_controller.dart';
import 'package:get/get.dart';
import 'package:hisabi/controller/voice_entry_controller.dart';

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
    Get.lazyPut<AutoListenController>(()         => AutoListenController(), fenix: true);

    // …and any others, e.g.:
    // Get.put(UserController());
    // Get.put(CategoryController());
  }
}
