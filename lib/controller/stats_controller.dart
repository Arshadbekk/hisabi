// lib/controller/stats_controller.dart
import 'package:expo_project/controller/transactions_list_controller.dart';
import 'package:expo_project/controller/transaxtion_controller.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class StatsController extends GetxController {
  final txListCtrl = Get.find<TransactionListController>();
  final txCtrl = Get.find<AddTransactionController>();

  // category → total amount
  final categoryStats = <CategoryModel, double>{}.obs;
  // currencyCode → total amount
  final currencyStats = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // whenever the transaction list changes, recompute
    ever(txListCtrl.transactions, (_) => _computeStats());
  }

  void _computeStats() {
    final catMap = <CategoryModel, double>{};
    final curMap = <String, double>{};

    for (var tx in txListCtrl.transactions) {
      // find the CategoryModel by ID:
      final cat = txCtrl.categories.firstWhere(
            (c) => c.id == tx.categoryId,
        orElse: () => CategoryModel(id: tx.categoryId, name: 'Unknown', iconName: ''),
      );
      catMap[cat] = (catMap[cat] ?? 0) + tx.amount;

      curMap[tx.currencyCode] = (curMap[tx.currencyCode] ?? 0) + tx.amount;
    }

    categoryStats.assignAll(catMap);
    currencyStats.assignAll(curMap);
  }
}
