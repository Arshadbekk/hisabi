// lib/view/transactions/analytics_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../constants/app_colors.dart';
import '../../controller/transactions_list_controller.dart';
import '../../controller/transaxtion_controller.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final txCtrl = Get.find<TransactionListController>();
  final addTxCtrl = Get.find<AddTransactionController>();
  late DateTime selectedMonth;
  int _activeTab = 0; // 0 = Monthly, 1 = Daily
  String? _selectedCurrency;
  final _monthScrollController = ScrollController();

  // Updated chart colors to complement mint-green primary
  final _chartColors = const [
    AppColors.primary,
    AppColors.accent1,
    AppColors.accent2,
    AppColors.accent3,
    AppColors.accent4,
    Color(0xFFEDC949),
    Color(0xFFAF7AA1),
    Color(0xFFFF9DA7),
    Color(0xFF9C755F),
    Color(0xFFBAB0AC),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: Obx(() {
        final months = _getAvailableMonths();
        final monthTx = _getMonthTransactions(months);
        final currencyGroups = _groupByCurrency(monthTx);
        final currencies = currencyGroups.keys.toList();

        if (_selectedCurrency == null && currencies.isNotEmpty) {
          _selectedCurrency = currencies.first;
        }

        return Column(
          children: [
            // Header
            _buildHeader(months),

            SizedBox(height: 10),
            // Currency Selector
            if (currencies.length > 1) _buildCurrencyTabs(currencies),

            // Main Content
            Expanded(
              child:
                  _selectedCurrency == null ||
                          !currencyGroups.containsKey(_selectedCurrency)
                      ? _buildEmptyState()
                      : _buildAnalyticsContent(
                        currencyGroups[_selectedCurrency]!,
                      ),
            ),
          ],
        );
      }),
    );
  }

  List<DateTime> _getAvailableMonths() {
    return txCtrl.transactions
        .map((tx) => DateTime(tx.date.year, tx.date.month))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  List<TransactionModel> _getMonthTransactions(List<DateTime> months) {
    return txCtrl.transactions.where((tx) {
      return tx.date.year == selectedMonth.year &&
          tx.date.month == selectedMonth.month;
    }).toList();
  }

  Map<String, List<TransactionModel>> _groupByCurrency(
    List<TransactionModel> transactions,
  ) {
    final map = <String, List<TransactionModel>>{};
    for (var tx in transactions) {
      final key = tx.currencySymbol;
      (map[key] ??= []).add(tx);
    }
    return map;
  }

  Widget _buildHeader(List<DateTime> months) {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(color: AppColors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 24),
          _buildMonthSelector(months),
          const SizedBox(height: 24),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(List<DateTime> months) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Month',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.darkGrey),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            controller: _monthScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: months.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final month = months[index];
              final isSelected = month == selectedMonth;
              return GestureDetector(
                onTap: () => setState(() => selectedMonth = month),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.grey,
                    ),
                  ),
                  child: Text(
                    DateFormat('MMM yyyy').format(month),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleButton('Monthly', 0),
          _buildToggleButton('Daily', 1),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.black : AppColors.darkGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyTabs(List<String> currencies) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: currencies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final currency = currencies[index];
          final isSelected = _selectedCurrency == currency;
          return GestureDetector(
            onTap: () => setState(() => _selectedCurrency = currency),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey,
                  width: 1.5,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : null,
              ),
              child: Center(
                child: Text(
                  currency,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsContent(List<TransactionModel> transactions) {
    final total = transactions.fold<double>(0, (sum, tx) => sum + tx.amount);
    final count = transactions.length;
    final avg = count > 0 ? total / count : 0.0;
    final fmt = NumberFormat.currency(
      symbol: '${_selectedCurrency} ',
      decimalDigits: addTxCtrl.selectedDecimalDigits.value,
    );

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                _MetricCard(label: 'Total', value: fmt.format(total)),
                const SizedBox(width: 12),
                _MetricCard(label: 'Transactions', value: count.toString()),
                const SizedBox(width: 12),
                _MetricCard(label: 'Avg. Txn', value: fmt.format(avg)),
              ],
            ),
            const SizedBox(height: 24),

            // Chart Section
            Text(
              _activeTab == 0 ? 'Spending by Category' : 'Daily Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 16),

            if (_activeTab == 0)
              _buildCategoryChart(transactions, total, fmt)
            else
              _buildDailyList(transactions, fmt),

            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(
    List<TransactionModel> transactions,
    double total,
    NumberFormat fmt,
  ) {
    final catMap = <String, double>{};
    for (var tx in transactions) {
      catMap[tx.categoryId] = (catMap[tx.categoryId] ?? 0) + tx.amount;
    }
    final catEntries =
        catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Premium color palette for the chart
    final premiumColors = const [
      Color(0xFF2A4C7D), // Deep navy
      Color(0xFF8C3D3D), // Burgundy
      Color(0xFF3D8C55), // Forest green
      Color(0xFFD4AF37), // Gold
      Color(0xFF2D9D9F), // Teal
      Color(0xFF5E4A9C), // Royal purple
      Color(0xFFD07D5A), // Terracotta
      Color(0xFF8A9A7B), // Sage
      Color(0xFF6A7F8F), // Slate blue
      Color(0xFFC06C84), // Mauve
    ];

    return Column(
      children: [
        SizedBox(
          height: 240, // Increased height for better visual presence
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 60, // Larger center space
                  sections: List.generate(catEntries.length, (i) {
                    final e = catEntries[i];
                    final pct = total == 0 ? 0.0 : e.value / total * 100;
                    return PieChartSectionData(
                      color: premiumColors[i % premiumColors.length],
                      value: e.value,
                      radius: pct >= 10 ? 32 : 28, // Emphasize larger segments
                      title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                    );
                  }),
                ),
              ),
              // Center text with total amount
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(total),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...catEntries.map((e) {
          final pct = total == 0 ? 0.0 : e.value / total * 100;
          final idxColor = catEntries.indexOf(e) % premiumColors.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: premiumColors[idxColor],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 4,
                        backgroundColor: AppColors.greyLight,
                        color: premiumColors[idxColor].withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  fmt.format(e.value),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDailyList(
    List<TransactionModel> transactions,
    NumberFormat fmt,
  ) {
    final daySum = <int, double>{};
    final dayCount = <int, int>{};
    for (var tx in transactions) {
      final d = tx.date.day;
      daySum[d] = (daySum[d] ?? 0) + tx.amount;
      dayCount[d] = (dayCount[d] ?? 0) + 1;
    }
    final days = daySum.keys.toList()..sort((a, b) => b.compareTo(a));

    if (days.isEmpty) {
      return Center(
        child: Text(
          'No transactions for selected period',
          style: TextStyle(
            color: AppColors.darkGrey.withOpacity(0.6),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final d = days[index];
        final date = DateFormat(
          'EEE, MMM d',
        ).format(DateTime(selectedMonth.year, selectedMonth.month, d));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Date Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dayCount[d]} transaction${dayCount[d]! > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.darkGrey.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    fmt.format(daySum[d]!),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 72, color: AppColors.accent2),
          const SizedBox(height: 16),
          Text(
            'No transactions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Add transactions to see analytics',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.darkGrey),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.darkGrey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
