import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';

class TransactionListController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// All transactions for the current month
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  /// Loading indicator
  final RxBool isLoading = false.obs;

  late String _uid;
  late String _monthId;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot>? _txSub;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes and refresh whenever user logs in/out
    _authSub = _auth.authStateChanges().listen((_) {
      refresh();
    });
    // Initial load
    refresh();
  }

  /// Tear down old listeners, clear state, and re-subscribe under the current user
  void refresh() {
    // Cancel previous Firestore listener
    _txSub?.cancel();
    // Clear out old transactions
    transactions.clear();
    isLoading.value = true;

    final user = _auth.currentUser;
    if (user == null) {
      // No user signed in—stop loading
      isLoading.value = false;
      return;
    }

    // Set up new IDs
    _uid = user.uid;
    _monthId = DateFormat('yyyy-MM').format(DateTime.now());

    // Begin listening for this user's transactions
    _listenTransactions();
  }

  void _listenTransactions() {
    _txSub = _db
        .collection('users')
        .doc(_uid)
        .collection('monthlySummaries')
        .doc(_monthId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
          (snap) {
            transactions.assignAll(
              snap.docs.map((doc) => TransactionModel.fromDoc(doc)).toList(),
            );
            isLoading.value = false;
          },
          onError: (err) {
            // handle errors if needed
            isLoading.value = false;
          },
        );
  }

  /// Delete a transaction and update the summary atomically
  Future<void> deleteTransaction(TransactionModel tx) async {
    isLoading.value = true;

    final txRef = _db
        .collection('users')
        .doc(_uid)
        .collection('monthlySummaries')
        .doc(_monthId)
        .collection('transactions')
        .doc(tx.id);

    final summaryRef = _db
        .collection('users')
        .doc(_uid)
        .collection('monthlySummaries')
        .doc(_monthId);

    await _db.runTransaction((txn) async {
      txn.delete(txRef);
      // decrement totalExpense by the transaction amount
      txn.update(summaryRef, {
        'totalExpense': FieldValue.increment(-tx.amount.abs()),
      });
    });

    isLoading.value = false;
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _txSub?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    refresh();
  }


}
