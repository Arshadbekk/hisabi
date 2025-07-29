// models/monthly_summary.dart
class MonthlySummary {
  final String monthId;       // e.g. "2025-07"
  final double totalIncome;
  final double totalExpense;
  double get totalSavings => totalIncome - totalExpense;

  MonthlySummary({
    required this.monthId,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory MonthlySummary.fromMap(Map<String,dynamic> m) => MonthlySummary(
    monthId:      m['month']        as String,
    totalIncome:  (m['totalIncome']  as num).toDouble(),
    totalExpense: (m['totalExpense'] as num).toDouble(),
  );

  Map<String,dynamic> toMap() => {
    'month':       monthId,
    'totalIncome': totalIncome,
    'totalExpense':totalExpense,
  };
}
