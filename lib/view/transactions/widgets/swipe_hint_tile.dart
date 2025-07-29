import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';

class SwipeHintTile extends StatefulWidget {
  final TransactionModel tx;
  final Color iconColor;
  final VoidCallback onDelete;

  const SwipeHintTile({
    required this.tx,
    required this.iconColor,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  _SwipeHintTileState createState() => _SwipeHintTileState();
}

class _SwipeHintTileState extends State<SwipeHintTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0),
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);

    // after first frame, do forward+reverse
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ctrl.forward();
      await _ctrl.reverse();
      _showDeleteDialog();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete this transaction?"),
        content: Text(widget.tx.description),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1) red delete background
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          height: 72, // match your ListTile height
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        // 2) sliding tile on top
        SlideTransition(
          position: _anim,
          child: Card(
            color: AppColors.white,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(CategoryModel.iconDataFor(widget.tx.categoryId),
                    color: widget.iconColor),
              ),
              title: Text(
                widget.tx.description,
                style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                DateFormat.MMMd().add_jm().format(widget.tx.date),
                style:
                const TextStyle(fontSize: 13, color: AppColors.darkGrey),
              ),
              trailing: Text(
                '${widget.tx.currencySymbol}${widget.tx.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
