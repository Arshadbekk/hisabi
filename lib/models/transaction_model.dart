// lib/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String currencyCode;
  final String currencySymbol;
  final String categoryId;
  final String description;
  final String paymentType;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.currencySymbol,
    required this.categoryId,
    required this.description,
    required this.paymentType,
    required this.date,
  });

  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data()! as Map<String, dynamic>;
    return TransactionModel(
      id:             doc.id,
      amount:         (m['amount'] as num).toDouble(),
      currencyCode:   m['currencyCode']  as String,
      currencySymbol: m['currencySymbol'] as String,
      categoryId:     m['categoryId']    as String,
      description:    m['description']   as String,
      paymentType:    m['paymentType']   as String,
      date:           (m['date'] as Timestamp).toDate(),
    );
  }

  /// Converts this model into a Map suitable for Firestore writes.
  Map<String, dynamic> toMap() {
    return {
      'amount'        : amount,
      'currencyCode'  : currencyCode,
      'currencySymbol': currencySymbol,
      'categoryId'    : categoryId,
      'description'   : description,
      'paymentType'   : paymentType,
      'date'          : Timestamp.fromDate(date),
    };
  }
}
