import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

enum AuthStatus {
  successful,
  userNotFound,
  roleMismatch,
  cancelled,
  failed,
}

class GoogleSignInRepository {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<AuthStatus> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return AuthStatus.cancelled;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = authResult.user;
      if (user == null) return AuthStatus.failed;

      final String uid = user.uid;

      final DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return AuthStatus.userNotFound;
      }

      final String role = userDoc.get('role') ?? '';
      if (role != 'User') {
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
        return AuthStatus.roleMismatch;
      }

      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
      }

      return AuthStatus.successful;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return AuthStatus.failed;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
