import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/app_colors.dart';
import '../../controller/home_controller.dart';
import '../../controller/transactions_list_controller.dart';
import '../../controller/transaxtion_controller.dart';
import '../../main_page.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Color get primaryText => const Color(0xFF0E1E40);
  Color get accentGreen => const Color(0xFF4CAF50);
  Color get accentPeach => const Color(0xFFFFA726);

  final HomeController hc = Get.put(HomeController());
  final TransactionListController txc = Get.put(TransactionListController());
  final AddTransactionController txAddCtrl = Get.put(
    AddTransactionController(),
  );

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    hc.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        final summary = hc.summary.value;
        if (summary == null) {
          return _buildShimmerSkeleton(context);
        }
        final income = summary.totalIncome;
        final spent = summary.totalExpense;
        final allTxs = txc.transactions;
        final recentTxs = allTxs.take(10).toList();
        final balance = income - spent;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildHeader('Financial Overview'),
                ),
              ),

              SliverToBoxAdapter(
                child: _buildSummaryCards(
                  balance,
                  spent,
                  income,
                  hc.user.value!.currencyCode,
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              // SliverToBoxAdapter(child: _buildTabs(theme, hc)),
              SliverToBoxAdapter(child: const SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: _buildSummaryCard(
                  theme,
                  income,
                  spent,
                  hc.user.value!.currencyCode,
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildTransactionsHeader(theme)),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),

              if (recentTxs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No transactions yet.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final tx = recentTxs[idx];
                    final isExpense = tx.amount > 0;

                    final color =
                        chartColors[tx.categoryId.hashCode.abs() %
                            chartColors.length];
                    return _buildTransactionItem(tx, color, context);
                  }, childCount: recentTxs.length),
                ),
              SliverToBoxAdapter(child: const SizedBox(height: 15)),
            ],
          ),
        );
      }),
    );
  }

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

  Widget _buildSummaryCards(
    double balance,
    double spent,
    double income,
    String currencyCode,
  ) {
    return SizedBox(
      height: 120,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryTopCard(
            "Total Balance",
            "${balance.toStringAsFixed(txAddCtrl.selectedDecimalDigits.value)} $currencyCode",
            Icons.account_balance_wallet,
            Color(0xFF16A085),
          ),
          const SizedBox(width: 16),
          _buildSummaryTopCard(
            "Monthly Spend",
            "${spent.toStringAsFixed(txAddCtrl.selectedDecimalDigits.value)} $currencyCode",
            Icons.trending_down,
            Color(0xFFC0392B),
          ),
          const SizedBox(width: 16),
          _buildSummaryTopCard(
            "Income",
            "${income.toStringAsFixed(txAddCtrl.selectedDecimalDigits.value)} $currencyCode",
            Icons.trending_up,
            Color(0xFF27AE60),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTopCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.darkGrey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, ${hc.user.value!.name}",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.black.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's your financial overview",
          style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
        ),
      ],
    );
  }

  Widget _buildTabs(ThemeData theme, HomeController hc) {
    return Row(
      children: List.generate(hc.tabs.length, (i) {
        final selected = i == hc.selectedTab.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => hc.selectedTab.value = i,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? accentGreen.withOpacity(0.1) : Colors.white,
                border: Border.all(
                  color: selected ? accentGreen : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  hc.tabs[i],
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: selected ? accentGreen : Colors.grey[600],
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    double income,
    double spent,
    String currencyCode,
  ) {
    // Premium minimal color palette
    const Color premiumTeal = Color(0xFF0A0A0A); // Teal for income
    const Color premiumCoral = Color(0xFFD4AF37); // Coral for spent

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Income row - updated dot color
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary, // Premium teal
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Income',
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${income.toStringAsFixed(txAddCtrl.selectedDecimalDigits.value)} $currencyCode',
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Spent row - updated dot color
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: premiumCoral, // Premium coral
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Spent',
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${spent.toStringAsFixed(txAddCtrl.selectedDecimalDigits.value)} $currencyCode',
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              height: 120,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 36,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      value: spent,
                      color: premiumCoral, // Matching coral
                      radius: 24,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: income - spent,
                      color: AppColors.primary, // Matching teal
                      radius: 24,
                      title: '',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent transactions',
          style: theme.textTheme.titleMedium!.copyWith(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: () {
            Get.to(
              () =>
                  MainPage(initialIndex: 1), // navigate straight to the 3rd tab
            );
          },
          child: const Text('See All'),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Salary':
        return Icons.account_balance;
      default:
        return Icons.receipt_long;
    }
  }

  Widget _buildShimmerSkeleton(BuildContext context) {
    final base = Colors.grey[300]!;
    final highlight = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 120, height: 24, color: base),
                CircleAvatar(radius: 16, backgroundColor: base),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(
                4,
                (_) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 32,
                    color: base,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(width: 200, height: 20, color: base),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder:
                    (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(width: 40, height: 40, color: base),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(height: 12, color: base),
                                const SizedBox(height: 6),
                                Container(height: 12, width: 100, color: base),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(width: 40, height: 12, color: base),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
