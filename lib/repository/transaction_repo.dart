// repositories/transaction_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String,dynamic>> _monthTxRef(String uid, String monthId) =>
      _firestore.collection('users')
          .doc(uid)
          .collection('monthlySummaries')
          .doc(monthId)
          .collection('transactions');

  Future<List<TransactionModel>> fetchAll(String uid, String monthId) async {
    final snap = await _monthTxRef(uid, monthId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => TransactionModel.fromDoc(d)).toList();
  }

  Future<void> add(
      String uid, String monthId, TransactionModel tx
      ) {
    return _monthTxRef(uid, monthId).doc(tx.id).set(tx.toMap());
  }

// update & delete omitted for brevity
}
