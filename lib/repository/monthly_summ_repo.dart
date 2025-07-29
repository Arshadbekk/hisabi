// repositories/monthly_summary_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_summary.dart';

class MonthlySummaryRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String,dynamic>> _summariesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('monthlySummaries');

  /// Fetch existing or return null
  Future<MonthlySummary?> fetch(String uid, String monthId) async {
    final doc = await _summariesRef(uid).doc(monthId).get();
    if (!doc.exists) return null;
    return MonthlySummary.fromMap(doc.data()!);
  }

  /// Initialize an empty summary
  Future<void> init(String uid, String monthId) {
    return _summariesRef(uid).doc(monthId).set(
        MonthlySummary(monthId: monthId, totalIncome: 0, totalExpense: 0).toMap()
    );
  }

  /// Increment‐ally update totals (atomic)
  Future<void> update(
      String uid,
      String monthId, {
        double incomeDelta = 0,
        double expenseDelta = 0,
      }) {
    final ref = _summariesRef(uid).doc(monthId);
    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      double prevInc  = 0;
      double prevExp  = 0;
      if (snap.exists) {
        final data = snap.data()!;
        prevInc = (data['totalIncome'] as num).toDouble();
        prevExp = (data['totalExpense'] as num).toDouble();
      }
      tx.set(ref, {
        'month':        monthId,
        'totalIncome':  prevInc + incomeDelta,
        'totalExpense': prevExp + expenseDelta,
      }, SetOptions(merge: true));
    });
  }
}
