import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/wallet_controller.dart';

class SavingsTargetCard extends StatelessWidget {
  final SavingTargetModel target;

  const SavingsTargetCard({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    final double percent = (target.current / target.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Circular Progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey[100],
                  color: Colors.purpleAccent,
                ),
              ),
              Icon(Icons.savings_outlined, color: Colors.purpleAccent, size: 24),
            ],
          ),
          const SizedBox(width: 16),
          // Info Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(target.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Terkumpul ${NumberFormat.compactCurrency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(target.current)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          // Add Button
          IconButton(
            onPressed: () {}, // Nanti tambahkan logika tambah tabungan
            icon: const Icon(Icons.add_circle, color: Colors.purpleAccent),
          )
        ],
      ),
    );
  }
}
