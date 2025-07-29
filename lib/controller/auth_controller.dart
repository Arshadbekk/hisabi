import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../repository/google_signin_repository.dart';

/// Controller to manage authentication flows and UI loading state.
class AuthController extends GetxController {
  /// Reactive loading flag for UI binding.
  final RxBool isLoading = false.obs;

  /// 1️⃣ Google Sign-In + redirect to registration if user does not exist
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final status = await GoogleSignInRepository.signInWithGoogle();

      switch (status) {
        case AuthStatus.successful:
          Get.snackbar('Success', 'Signed in successfully!');
          Get.offAllNamed('/main');
          break;

        case AuthStatus.userNotFound:
          Get.snackbar(
            'Error',
            'User record not found. Please register first.',
          );
          Get.toNamed('/register');
          break;

        case AuthStatus.roleMismatch:
          Get.snackbar(
            'Access Denied',
            'Only users with role "User" can sign in.',
          );
          break;

        case AuthStatus.cancelled:
          Get.snackbar('Cancelled', 'Google sign-in was cancelled.');
          await GoogleSignInRepository.signOut();
          break;

        case AuthStatus.failed:
        default:
          Get.snackbar('Error', 'Sign-in failed. Please try again.');
          break;
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 2️⃣ Sign out and notify UI
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await GoogleSignInRepository.signOut();
      Get.snackbar('Signed out', 'You have been signed out.');
      // Optionally navigate to login: Get.offAllNamed('/login');
      Get.offAllNamed('/signUp');
    } catch (e) {
      Get.snackbar('Error', 'Sign-out failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 3️⃣ Register a new user after Google sign-in
  Future<void> registerUser({
    required String name,
    required String phoneNumber,
    required String countryCode,
    required bool notificationsEnabled,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      Get.snackbar('Error', 'No authenticated user found.');
      return;
    }

    final userData = <String, dynamic>{
      'uid': firebaseUser.uid,
      'email': firebaseUser.email,
      'name': name.trim(),
      'phoneNumber': phoneNumber.trim(),
      'countryCode': countryCode,
      'notificationsEnabled': notificationsEnabled,
      'role': 'User',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      isLoading.value = true;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userData);

      Get.snackbar('Welcome', 'Account created successfully!');
      Get.offAllNamed('/onBoarding');
    } catch (e) {
      Get.snackbar('Error', 'Failed to register user: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
