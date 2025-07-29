import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:currency_picker/currency_picker.dart';

import '../routes/app_routes.dart';

class OnboardingController extends GetxController {
  /// Holds the currency the user picked
  final selectedCurrency = Rxn<Currency>();

  final RxBool isLoading = false.obs;

  /// Holds the income the user entered
  final monthlyIncome = 0.0.obs;

  /// Call when currency page picks a value
  void setCurrency(Currency currency) {
    selectedCurrency.value = currency;
  }

  /// Call when income page submits a value
  void setIncome(String raw) {
    monthlyIncome.value = double.tryParse(raw) ?? 0.0;
  }

  /// Writes the onboarding fields into Firestore
  Future<void> completeOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No signed-in user');
    }
    isLoading.value=true;

    final data = {
      'currencyCode': selectedCurrency.value?.code ?? '',
      'currencySymbol': selectedCurrency.value?.symbol ?? '',
      'monthlyIncome': monthlyIncome.value,
      'onboardingComplete': true,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
    isLoading.value=false;
    Get.offAllNamed(AppRoutes.main);
  }
}
