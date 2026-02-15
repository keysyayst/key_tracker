import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetCard extends StatelessWidget {
  final double limit;
  final double spent;

  const BudgetCard({super.key, required this.limit, required this.spent});

  @override
  Widget build(BuildContext context) {
    final double percent = (spent / limit).clamp(0.0, 1.0);
    final Color barColor = percent > 0.9 ? Colors.red : (percent > 0.7 ? Colors.orange : Colors.blue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pengeluaran Minggu Ini', style: TextStyle(color: Colors.grey)),
              Text('${(percent * 100).toStringAsFixed(0)}%', style: TextStyle(color: barColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.grey[100],
              color: barColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(spent),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'dari ${NumberFormat.compact(locale: 'id').format(limit)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
