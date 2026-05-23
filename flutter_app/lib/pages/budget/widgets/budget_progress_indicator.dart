import 'package:flutter/material.dart';

// BR4 - Visual indicator for budget limit
class BudgetProgressIndicatorWidget extends StatelessWidget {
  final double spent;
  final double total;
  final bool isOverBudget;
  final bool showLabel;

  const BudgetProgressIndicatorWidget({
    super.key,
    required this.spent,
    required this.total,
    required this.isOverBudget,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);
    Color barColor;
    if (isOverBudget || progress >= 1.0) {
      barColor = Colors.red;
    } else if (progress >= 0.8) {
      barColor = Colors.orange;
    } else {
      barColor = const Color(0xFF00897B);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
          minHeight: 10,
        ),
      ),
      if (showLabel) ...[
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            '$pct% used',
            style: TextStyle(fontSize: 12, color: barColor, fontWeight: FontWeight.w600),
          ),
          if (isOverBudget)
            const Text(
              'OVER BUDGET',
              style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ]),
      ],
    ]);
  }
}
