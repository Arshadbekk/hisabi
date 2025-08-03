import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/monthly_summary.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

/// HomeController now listens for auth state changes and re-subscribes streams
class HomeController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late String _userId;
  late String _monthId;
  final _db = FirebaseFirestore.instance;
  // Reactive state
  final user = Rxn<UserModel>();
  final summary = Rxn<MonthlySummary>();
  final transactions = <TransactionModel>[].obs;
  final selectedTab = 0.obs;

  // UI tabs
  final tabs = ['All', 'Daily', 'Weekly', 'Monthly'];

  // Subscriptions
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<DocumentSnapshot>? _summarySub;
  StreamSubscription<QuerySnapshot>? _txSub;

  @override
  void onInit() {
    super.onInit();

    // Listen to auth state changes
    _authSub = _auth.authStateChanges().listen(_handleAuthChange);
    // _listenToSummary();
  }

  void _handleAuthChange(User? firebaseUser) {
    // Cancel any existing subscriptions
    _userSub?.cancel();
    _summarySub?.cancel();
    _txSub?.cancel();

    if (firebaseUser != null) {
      // New user logged in
      _userId = firebaseUser.uid;
      _monthId = DateFormat('yyyy-MM').format(DateTime.now());

      _listenToUser();
      // listenToSummary();
      // _listenToTransactions();

    } else {
      // User signed out
      user.value = null;
      summary.value = null;
      transactions.clear();
    }
  }

  void _listenToUser() {
    _userSub = _firestore.collection('users').doc(_userId).snapshots().listen((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        user.value = UserModel.fromMap(doc.data()!);
      }
    });
  }

  void listenToSummary() {
    final summaryDoc = _firestore
        .collection('users')
        .doc(_userId)
        .collection('monthlySummaries')
        .doc(_monthId);

    debugPrint("📅 Starting summary listener for user=$_userId month=$_monthId");

    _summarySub = summaryDoc.snapshots().listen(
          (doc) {
        try {
          if (doc.exists && doc.data() != null) {
            // existing summary → hydrate normally
            final data = doc.data()!;
            summary.value = MonthlySummary.fromMap(data);
            debugPrint("✅ Loaded existing MonthlySummary: ${summary.value}");
          } else {
            // no summary yet → initialize from user's monthlyIncome
            final initialIncome = user.value?.monthlyIncome ?? 0.0;
            debugPrint("ℹ️ No summary found; initializing with monthlyIncome=$initialIncome");

            // update local Rx
            summary.value = MonthlySummary(
              monthId: _monthId,
              totalIncome: initialIncome,
              totalExpense: 0,
            );

            // persist the new document
            summaryDoc
                .set({
              'month': _monthId,
              'totalIncome': initialIncome,
              'totalExpense': 0,
            })
                .then((_) {
              debugPrint("💾 Successfully created initial summary doc for $_monthId");
            })
                .catchError((error, stack) {
              debugPrint("❌ Failed to persist initial summary: $error\n$stack");
            });
          }
        } catch (e, stack) {
          debugPrint("🚨 Exception in summary snapshot handler: $e\n$stack");
        }
      },
      onError: (error, stack) {
        debugPrint("👂 Error listening to summary snapshots: $error\n$stack");
      },
      onDone: () {
        debugPrint("🔒 Summary snapshot listener closed for month=$_monthId");
      },
    );
  }



  void listenToTransactions() {
    _txSub = _firestore
        .collection('users')
        .doc(_userId)
        .collection('monthlySummaries')
        .doc(_monthId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
          final list =
              snap.docs.map((ds) => TransactionModel.fromDoc(ds)).toList();
          transactions.assignAll(list);
        });
  }

  /// Adds a new transaction and updates summary atomically

  // inside HomeController
  Future<void> updateUser(Map<String, dynamic> data) async {
    final userRef = _firestore.collection('users').doc(_userId);
    await userRef.update(data);
  }

  /// call this any time you need to completely re-subscribe
  void refresh() {
    // tear down
    _userSub?.cancel();
    _summarySub?.cancel();
    _txSub?.cancel();

    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _userId = firebaseUser.uid;
      _monthId = DateFormat('yyyy-MM').format(DateTime.now());

      _listenToUser();
      listenToSummary();
      listenToTransactions();
    } else {
      // if no user, clear the state:
      user.value = null;
      summary.value = null;
      transactions.clear();
    }
  }

  /// Update the user’s currency code + symbol in their user doc
  /// and merge both into this month’s summary.
  Future<void> updateCurrency(
    String currencyCode,
    String currencySymbol,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'No user signed in');
      return;
    }

    final userRef = _db.collection('users').doc(user.uid);
    final monthId = DateFormat('yyyy-MM').format(DateTime.now());
    final summaryRef = userRef.collection('monthlySummaries').doc(monthId);

    final data = {
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
    };

    try {
      final batch = _db.batch();
      batch.update(userRef, data);
      batch.set(summaryRef, data, SetOptions(merge: true));
      await batch.commit();

      Get.snackbar(
        'Success',
        'Currency set to $currencyCode ($currencySymbol)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _userSub?.cancel();
    _summarySub?.cancel();
    _txSub?.cancel();
    super.onClose();
  }
}
