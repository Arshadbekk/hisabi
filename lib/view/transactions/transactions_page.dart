import 'package:expo_project/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

import '../../constants/app_colors.dart';
import '../../controller/transactions_list_controller.dart';
import '../../controller/transaxtion_controller.dart';
import '../../models/category_model.dart';
import 'add_transactions_page.dart';
import 'analytics_page.dart';

class TransactionsPage extends StatefulWidget {
  TransactionsPage({Key? key}) : super(key: key);

  static bool _didShowSwipeTip = false;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final txCtrl = Get.find<TransactionListController>();

  final txAddCtrl = Get.find<AddTransactionController>();

  final Rx<Period> period = Period.month.obs;

  final selectedDay = DateTime.now().obs;

  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;

  final chartColors = const [
    Color(0xFF1F1F1F), // Charcoal
    Color(0xFF4A4A4A), // Graphite
    Color(0xFFD4AF37), // Premium Gold
    Color(0xFFC0C0C0), // Silver
    Color(0xFFF2E8CF), // Champagne
    Color(0xFF003366), // Deep Navy
    Color(0xFF800020), // Merlot
    Color(0xFF013220), // Emerald
  ];
  late final List<DateTime> _availableDays;
  late final List<DateTime> _availableMonths;
  bool _datesComputed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      txCtrl.refresh();
    });
    // whenever isLoading flips to false, compute once:
    ever<bool>(txCtrl.isLoading, (loading) {
      if (!loading && !_datesComputed) {
        _computeAvailableDates();
        _datesComputed = true;
      }
    });
  }

  void _computeAvailableDates() {
    final txs = txCtrl.transactions;
    _availableDays =
        txs
            .map((tx) => DateTime(tx.date.year, tx.date.month, tx.date.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    _availableMonths =
        txs.map((tx) => DateTime(tx.date.year, tx.date.month)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

    // if you want, default your selectedDay/month to the newest:
    if (_availableDays.isNotEmpty) selectedDay.value = _availableDays.first;
    if (_availableMonths.isNotEmpty)
      selectedMonth.value = _availableMonths.first;

    // trigger rebuild so the picker guard clauses see real data
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    timeDilation = 1.5; // Slow down animations for premium feel
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: Obx(() {
        if (txCtrl.isLoading.value) return _buildShimmerLoading();

        final filtered = _getFilteredTransactions();
        final byCurrency = <String, List<TransactionModel>>{};
        for (var tx in filtered) {
          byCurrency.putIfAbsent(tx.currencyCode, () => []).add(tx);
        }
        final symbols = byCurrency.keys.toList();

        // Use the symbols.length as a ValueKey so DefaultTabController
        // rebuilds whenever the tab count changes.
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DefaultTabController(
            key: ValueKey(symbols.length), // ← rebuild on length change
            length: symbols.length,
            child: NestedScrollView(
              headerSliverBuilder: (_, __) {
                final slivers = <Widget>[
                  SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _buildPeriodSelector()),
                  SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildDateSelector(context)),
                  SliverToBoxAdapter(child: SizedBox(height: 32)),
                  SliverToBoxAdapter(child: _buildTotalCard()),
                ];

                // only add the tabs if there’s more than one currency
                if (symbols.length > 1) {
                  slivers.add(
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabBarDelegate(
                        TabBar(
                          isScrollable: true,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.darkGrey,
                          indicatorColor: AppColors.primary,
                          tabs: symbols.map((sym) => Tab(text: sym)).toList(),
                        ),
                      ),
                    ),
                  );
                }

                return slivers;
              },
              // if multiple currencies show a TabBarView, else a single ListView
              body:
                  symbols.length > 1
                      ? TabBarView(
                        children:
                            symbols.map((sym) {
                              final txs = byCurrency[sym]!;
                              return ListView.builder(
                                physics: BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: txs.length,
                                itemBuilder: (_, i) {
                                  final tx = txs[i];
                                  final color =
                                      chartColors[tx.categoryId.hashCode.abs() %
                                          chartColors.length];
                                  return _buildTransactionItem(
                                    tx,
                                    color,
                                    context,
                                  );
                                },
                              );
                            }).toList(),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final tx = filtered[i];
                          final color =
                              chartColors[tx.categoryId.hashCode.abs() %
                                  chartColors.length];
                          return _buildTransactionItem(tx, color, context);
                        },
                      ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PeriodChip(
            label: 'Day',
            isSelected: period.value == Period.day,
            onTap: () => period.value = Period.day,
          ),
          const SizedBox(width: 12),
          _PeriodChip(
            label: 'Month',
            isSelected: period.value == Period.month,
            onTap: () => period.value = Period.month,
          ),
        ],
      ),
    );
  }

  // Widget _buildDateSelector(BuildContext context) {
  //   return AnimatedSwitcher(
  //     duration: const Duration(milliseconds: 400),
  //     transitionBuilder: (child, animation) {
  //       return SlideTransition(
  //         position: Tween<Offset>(
  //           begin: const Offset(0, 0.2),
  //           end: Offset.zero,
  //         ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
  //         child: FadeTransition(opacity: animation, child: child),
  //       );
  //     },
  //     child:
  //         period.value == Period.day
  //             ? _DateSelectorCard(
  //               key: const ValueKey('day'),
  //               icon: Icons.calendar_today_rounded,
  //               label: DateFormat.yMMMd().format(selectedDay.value),
  //               onTap: () async {
  //                 final picked = await showDatePicker(
  //                   context: context,
  //                   initialDate: selectedDay.value,
  //                   firstDate: _availableDays.first,
  //                   lastDate: _availableDays.last,
  //                   selectableDayPredicate: (date) {
  //                     final d = DateTime(date.year, date.month, date.day);
  //                     return _availableDays.contains(d);
  //                   },
  //                   builder: (ctx, child) => Theme(
  //                     data: ThemeData.light().copyWith(
  //                       colorScheme: const ColorScheme.light(primary: AppColors.primary),
  //                     ),
  //                     child: child!,
  //                   ),
  //                 );
  //                 if (picked != null) selectedDay.value = picked;
  //
  //               },
  //             )
  //             : _DateSelectorCard(
  //               key: const ValueKey('month'),
  //               icon: Icons.date_range_rounded,
  //               label: DateFormat.yMMM().format(selectedMonth.value),
  //               onTap: () async {
  //                 final months = List.generate(12, (i) {
  //                   final now = DateTime.now();
  //                   return DateTime(now.year, now.month - i);
  //                 });
  //
  //                 final picked = await showModalBottomSheet<DateTime>(
  //                   context: context,
  //                   shape: const RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //                   ),
  //                   builder: (_) => Container(
  //                     decoration: const BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //                     ),
  //                     child: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Container(
  //                           width: 40, height: 4,
  //                           margin: const EdgeInsets.symmetric(vertical: 12),
  //                           decoration: BoxDecoration(
  //                             color: Colors.grey[300], borderRadius: BorderRadius.circular(2),
  //                           ),
  //                         ),
  //                         Flexible(
  //                           child: ListView(
  //                             shrinkWrap: true,
  //                             children: _availableMonths.map((m) {
  //                               return ListTile(
  //                                 title: Text(
  //                                   DateFormat.yMMM().format(m),
  //                                   textAlign: TextAlign.center,
  //                                   style: const TextStyle(fontSize: 18),
  //                                 ),
  //                                 onTap: () => Navigator.pop(context, m),
  //                               );
  //                             }).toList(),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //                 if (picked != null) selectedMonth.value = picked;
  //               },
  //             ),
  //   );
  // }

  Widget _buildDateSelector(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child:
          period.value == Period.day
              // ─── Day picker ─────────────────────────────────
              ? _DateSelectorCard(
                key: const ValueKey('day'),
                icon: Icons.calendar_today_rounded,
                label: DateFormat.yMMMd().format(selectedDay.value),
                onTap: () async {
                  if (_availableDays.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No transactions on any day'),
                      ),
                    );
                    return;
                  }
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDay.value,
                    firstDate: _availableDays.last,
                    lastDate: _availableDays.first,
                    selectableDayPredicate: (date) {
                      final d = DateTime(date.year, date.month, date.day);
                      return _availableDays.contains(d);
                    },
                    builder:
                        (ctx, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                          ),
                          child: child!,
                        ),
                  );
                  if (picked != null) selectedDay.value = picked;
                },
              )
              // ─── Month picker ───────────────────────────────
              : _DateSelectorCard(
                key: const ValueKey('month'),
                icon: Icons.date_range_rounded,
                label: DateFormat.yMMM().format(selectedMonth.value),
                onTap: () async {
                  if (_availableMonths.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No transactions in any month'),
                      ),
                    );
                    return;
                  }
                  final picked = await showModalBottomSheet<DateTime>(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder:
                        (_) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Flexible(
                                child: ListView(
                                  shrinkWrap: true,
                                  children:
                                      _availableMonths.map((m) {
                                        return ListTile(
                                          title: Text(
                                            DateFormat.yMMM().format(m),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                          onTap:
                                              () => Navigator.pop(context, m),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                  );
                  if (picked != null) selectedMonth.value = picked;
                },
              ),
    );
  }

  Widget _buildTotalCard() {
    final filtered = _getFilteredTransactions();
    final sums = _sumCurrencies(filtered);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child:
          sums.length == 1
              ? _buildSingleCurrency(sums)
              : _buildMultiCurrency(sums),
    );
  }

  Map<String, double> _sumCurrencies(List<TransactionModel> transactions) {
    final Map<String, double> sums = {};
    for (var tx in transactions) {
      sums[tx.currencySymbol] = (sums[tx.currencySymbol] ?? 0) + tx.amount;
    }
    return sums;
  }

  Widget _buildSingleCurrency(Map<String, double> sums) {
    final entry = sums.entries.first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Balance',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              entry.key,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                entry.value.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiCurrency(Map<String, double> sums) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Balance',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              sums.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.value.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  /// Builds a single transaction tile.
  /// Uses a tinted background if the transaction currency differs from the user’s chosen currency.
  Widget _buildTransactionItem(
    TransactionModel tx,
    Color color,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {},
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Leading icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CategoryModel.iconDataFor(tx.categoryId),
                      color: color,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.MMMd().add_jm().format(tx.date),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount and delete button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tx.currencySymbol}${tx.amount.toStringAsFixed(txAddCtrl.selectedDecimalDigits.value)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDeleteButton(context, tx),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, TransactionModel tx) {
    return GestureDetector(
      onTap: () => _showDeleteDialog(context, tx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text(
              'Delete',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TransactionModel tx) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // // Animated trash icon
                  // Lottie.asset(
                  //   'assets/animations/trash.json',
                  //   height: 120,
                  //   repeat: false,
                  // ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Delete Transaction?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'This will permanently remove\n${tx.description}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Delete button
                      ElevatedButton(
                        onPressed: () {
                          txCtrl.deleteTransaction(tx);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  List<TransactionModel> _getFilteredTransactions() {
    return txCtrl.transactions.where((tx) {
      final d = tx.date;
      if (period.value == Period.day) {
        return d.year == selectedDay.value.year &&
            d.month == selectedDay.value.month &&
            d.day == selectedDay.value.day;
      } else {
        return d.year == selectedMonth.value.year &&
            d.month == selectedMonth.value.month;
      }
    }).toList();
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 80),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 40),
        Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 40),
        ...List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DateSelectorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateSelectorCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more_rounded, color: AppColors.darkGrey),
            ],
          ),
        ),
      ),
    );
  }
}

enum Period { day, month }

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // wrap in a Container if you need a background
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
