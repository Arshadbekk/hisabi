import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hisabi/services/hive_services.dart';
import '../models/txn.dart';

class SyncService {
  /// Push local unsynced to Firestore if user is not anonymous
  static Future<void> syncToCloud({required String monthId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final firestore = FirebaseFirestore.instance;
    final summaryDoc = firestore
        .collection('users')
        .doc(user.uid)
        .collection('monthlySummaries')
        .doc(monthId);
    final txColl = summaryDoc.collection('transactions');

    final unsynced = HiveService.getUnsyncedTxns();
    if (unsynced.isEmpty) return;

    // Sum all local amounts as expenses
    final expenseSum = unsynced.fold<double>(
      0,
      (sum, txn) => sum + txn.amount.abs(),
    );

    // Start a batch
    final batch = firestore.batch();

    // Increment only totalExpense
    batch.set(summaryDoc, {
      'totalExpense': FieldValue.increment(expenseSum),
    }, SetOptions(merge: true));

    // Add each transaction doc
    for (final txn in unsynced) {
      final docRef = txColl.doc(txn.id);
      batch.set(docRef, {
        'id': txn.id,
        'amount': txn.amount,
        'formattedAmount': txn.formattedAmount,
        'currencyCode': txn.currencyCode,
        'currencySymbol': txn.currencySymbol,
        'categoryId': txn.categoryId,
        'categoryName': txn.categoryName,
        'description': txn.description,
        'paymentType': txn.paymentType,
        'date': Timestamp.fromDate(txn.date),
      });
      await HiveService.markAsSynced(txn.id);
    }

    // Commit everything at once
    await batch.commit();
     // 5️⃣ Clear local Hive data now that it’s safely in Firestore
  await HiveService.clearAllTxns();
  }
}
