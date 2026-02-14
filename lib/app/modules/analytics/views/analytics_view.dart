import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../themes/app_colors.dart';
import '../../../widgets/pastel_card.dart';
import '../controllers/analytics_controller.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgRose,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final e = controller.error.value;
            if (e != null) {
              return Center(child: Text(e, style: const TextStyle(color: Colors.red)));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    ),
                    IconButton(
                      onPressed: controller.load,
                      icon: const Icon(Icons.refresh_rounded),
                    )
                  ],
                ),
                const SizedBox(height: 12),

                PastelCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _metric('Focus (7d)', '${controller.focusMinutes7d.value} menit'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metric('Net (7d)',
                            'Rp ${(controller.income7d.value - controller.expense7d.value).toStringAsFixed(0)}'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text('Habit completion (7 hari)', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.separated(
                    itemCount: controller.last7Days.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final d = controller.last7Days[i];
                      return PastelCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 92,
                              child: Text(d.date, style: const TextStyle(fontWeight: FontWeight.w900)),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: d.ratio,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(999),
                                backgroundColor: AppColors.gray100,
                                color: AppColors.pink400,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('${d.done}/${d.total}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
      ],
    );
  }
}
