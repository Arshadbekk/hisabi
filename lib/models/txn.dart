import 'package:hive/hive.dart';

part 'txn.g.dart';

@HiveType(typeId: 0)
class Txn extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String formattedAmount;

  @HiveField(3)
  String currencyCode;

  @HiveField(4)
  String currencySymbol;

  @HiveField(5)
  String categoryId;

  @HiveField(6)
  String categoryName;

  @HiveField(7)
  String description;

  @HiveField(8)
  String paymentType;

  @HiveField(9)
  DateTime date;

  // Remove `final` so we can modify it later:
  @HiveField(10)
  bool isSynced;

  Txn({
    required this.id,
    required this.amount,
    required this.formattedAmount,
    required this.currencyCode,
    required this.currencySymbol,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.paymentType,
    required this.date,
    this.isSynced = false,  // default false
  });
}
