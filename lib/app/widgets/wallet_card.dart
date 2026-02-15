import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/wallet_controller.dart';

class WalletCard extends StatelessWidget {
  final WalletModel wallet;

  const WalletCard({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: wallet.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(wallet.icon, color: wallet.color, size: 20),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(wallet.name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                NumberFormat.compactCurrency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(wallet.balance),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          )
        ],
      ),
    );
  }
}
