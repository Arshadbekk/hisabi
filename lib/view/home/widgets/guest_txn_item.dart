// lib/widgets/guest_transaction_item.dart

import 'package:flutter/material.dart';
import 'package:hisabi/constants/app_colors.dart';
import 'package:hisabi/models/category_model.dart';
import 'package:hisabi/models/txn.dart';

import 'package:intl/intl.dart';

class GuestTransactionItem extends StatelessWidget {
  final Txn txn;
  final Color color;

  const GuestTransactionItem({
    Key? key,
    required this.txn,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final amountText = '${txn.currencySymbol}${txn.amount.toStringAsFixed(2)}';
    final dateText = DateFormat.MMMd().add_jm().format(txn.date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            CategoryModel.iconDataFor(txn.categoryId),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          txn.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(dateText),
        trailing: Text(
          amountText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }
}
