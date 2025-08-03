import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hisabi/controller/voice_entry_controller.dart';
import 'package:hisabi/models/txn.dart';
import 'package:hisabi/services/hive_services.dart';
import 'package:hisabi/view/home/widgets/features_row.dart';
import 'package:hisabi/view/home/widgets/guest_txn_item.dart';
import 'package:hisabi/view/transactions/add_transactions_page.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  final storage = GetStorage();
  bool _didShowSwipeHint = false;

  late final bool isGuest;

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
    // 1️⃣ Determine guest mode once
    isGuest = storage.read<bool>('isGuest') ?? false;

    // 2️⃣ Only initialize data listeners if NOT guest
    if (!isGuest) {
      hc.refresh();
      hc.listenToSummary();
      hc.listenToTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return isGuest
        ? _buildGuestView()
        : Scaffold(
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

  Widget _buildGuestView() {
    final theme = Theme.of(context);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // 1) Get local txns (will be empty for new guest)
    final localTxns = HiveService.getAllTxns();

    // 2) Compute totals (both zero if no data)
    final spent = localTxns.fold<double>(0, (sum, t) => sum + t.amount);
    final income = 0.0;
    final balance = income - spent;

    // 3) Prepare category breakdown (empty for no data)
    final Map<String, double> categoryTotals = {};
    for (final t in localTxns) {
      categoryTotals[t.categoryId] =
          (categoryTotals[t.categoryId] ?? 0) + t.amount;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AddTransactionPage()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, statusBarHeight + 16, 16, 16),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Greeting
            SliverToBoxAdapter(
              child: Text(
                'Hello, Guest 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black.withOpacity(0.8),
                ),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Text(
                "Here's a preview of your dashboard:",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),

            // Summary Cards with zeros
            // Live summary cards
            ValueListenableBuilder<Box<Txn>>(
              valueListenable: Hive.box<Txn>('transactions').listenable(),
              builder: (_, box, __) {
                final txns = box.values.toList();
                final spent = txns.fold<double>(0, (sum, t) => sum + t.amount);
                final income = 0.0;
                final balance = income - spent;
                // Read the user’s chosen currency:
                final code = txAddCtrl.selectedCurrencyCode.value;
                final sym = txAddCtrl.selectedCurrencySymbol.value;

                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildSummaryTopCard(
                          "Balance",
                          "${balance.toStringAsFixed(txAddCtrl.selectedDecimalDigits.value)} $code",
                          Icons.account_balance_wallet,
                          const Color(0xFF16A085),
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryTopCard(
                          "Spent",
                          "${spent.toStringAsFixed(txAddCtrl.selectedDecimalDigits.value)} $code",
                          Icons.trending_down,
                          const Color(0xFFC0392B),
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryTopCard(
                          "Income",
                          "${income.toStringAsFixed(txAddCtrl.selectedDecimalDigits.value)} $code",
                          Icons.trending_up,
                          const Color(0xFF27AE60),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),

            // Pie Chart (placeholder if no data)
            // Live pie chart + legend
            ValueListenableBuilder<Box<Txn>>(
              valueListenable: Hive.box<Txn>('transactions').listenable(),
              builder: (_, box, __) {
                // Recompute category totals
                final Map<String, double> totals = {};
                for (final t in box.values) {
                  totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
                }

                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SizedBox(
                      height: 180,
                      child:
                          totals.isEmpty
                              ? const Center(
                                child: Text(
                                  'No spending data yet',
                                  style: TextStyle(color: Colors.black38),
                                ),
                              )
                              : Row(
                                children: [
                                  // Pie chart
                                  Expanded(
                                    flex: 2,
                                    child: PieChart(
                                      PieChartData(
                                        centerSpaceRadius: 40,
                                        sectionsSpace: 4,
                                        sections:
                                            totals.entries.map((e) {
                                              final color =
                                                  chartColors[e.key.hashCode
                                                          .abs() %
                                                      chartColors.length];
                                              return PieChartSectionData(
                                                value: e.value,
                                                color: color,
                                                radius: 50,
                                                title: '',
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Legend
                                  Expanded(
                                    flex: 1,
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children:
                                            totals.entries.map((e) {
                                              final color =
                                                  chartColors[e.key.hashCode
                                                          .abs() %
                                                      chartColors.length];
                                              final cat = txAddCtrl.categories
                                                  .firstWhere(
                                                    (c) => c.id == e.key,
                                                    orElse:
                                                        () => CategoryModel(
                                                          id: e.key,
                                                          name: e.key,
                                                          iconName: '',
                                                        ),
                                                  );
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    cat.name,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                );
              },
            ),

            SliverToBoxAdapter(child: const SizedBox(height: 24)),

            // Recent Activity header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Recent Activity',
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),

            // // Transaction list or empty message
            // if (localTxns.isEmpty)
            //   SliverFillRemaining(
            //     hasScrollBody: false,
            //     child: Center(
            //       child: Text(
            //         'No transactions yet.\nTap + to add one.',
            //         textAlign: TextAlign.center,
            //         style: TextStyle(fontSize: 16, color: Colors.black38),
            //       ),
            //     ),
            //   )
            // else
            // Replace the old SliverToBoxAdapter+ValueListenableBuilder with this:
            ValueListenableBuilder<Box<Txn>>(
              valueListenable: Hive.box<Txn>('transactions').listenable(),
              builder: (context, box, _) {
                final localTxns = box.values.toList();

                if (localTxns.isEmpty) {
                  // Show an empty‐state sliver
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No transactions yet.\nTap + to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black38),
                      ),
                    ),
                  );
                }

                // Otherwise, show the sliver list of items
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final tx = localTxns[idx];
                    final color =
                        chartColors[tx.categoryId.hashCode.abs() %
                            chartColors.length];

                    return Slidable(
                      key: ValueKey(tx.id),

                      // // full-swipe support
                      // d: DismissiblePane(onDismissed: () {
                      //   txAddCtrl.deleteTransaction(tx);
                      // }),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            autoClose: true,
                            onPressed: (_) => txAddCtrl.deleteTransaction(tx),
                            backgroundColor: Colors.grey.shade50,
                            foregroundColor: Colors.red,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),

                      // this LayoutBuilder gives us the right context to call Slidable.of()
                      child: LayoutBuilder(
                        builder: (innerContext, constraints) {
                          // only show once, on the very first item
                          if (!_didShowSwipeHint && idx == 0) {
                            _didShowSwipeHint = true;
                            // schedule after build
                            WidgetsBinding.instance.addPostFrameCallback((
                              _,
                            ) async {
                              final slidable = Slidable.of(innerContext);
                              // reveal the delete actions
                              slidable?.openEndActionPane(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                              );
                              // let it linger so they see it
                              await Future.delayed(
                                const Duration(milliseconds: 800),
                              );
                              slidable?.close();
                            });
                          }

                          return GuestTransactionItem(txn: tx, color: color);
                        },
                      ),
                    );
                  }, childCount: localTxns.length),
                );
              },
            ), // Sign-in CTA
            SliverToBoxAdapter(child: const SizedBox(height: 32)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlock More Features',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 12),

                        FeatureRow(
                          icon: Icons.cloud_upload,
                          title: 'Cloud Backup',
                          subtitle: 'Keep your history safe and synced',
                        ),

                        FeatureRow(
                          icon: Icons.bar_chart,
                          title: 'Advanced Analytics',
                          subtitle: 'Insights on your spending habits',
                        ),

                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => Get.toNamed('/signUp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(200, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Sign In to Unlock'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
