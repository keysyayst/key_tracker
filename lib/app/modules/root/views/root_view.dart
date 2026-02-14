import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/pastel_bottom_nav.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../analytics/views/analytics_view.dart';
import '../../books/views/books_view.dart';
import '../../profile/views/profile_view.dart';
import '../controllers/root_controller.dart';
import '../../../themes/app_colors.dart';

class RootView extends GetView<RootController> {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DashboardView(),
      AnalyticsView(),
      BooksView(),
      ProfileView(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            return IndexedStack(
              index: controller.tabIndex.value,
              children: pages,
            );
          }),

          // Bottom nav bubble
          Align(
            alignment: Alignment.bottomCenter,
            child: Obx(() {
              return PastelBottomNav(
                index: controller.tabIndex.value,
                onTap: controller.setTab,
              );
            }),
          ),

          // Center FAB
          Positioned(
            bottom: 62,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: controller.onFab,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.pink500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55EC4899), blurRadius: 18, offset: Offset(0, 10)),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, size: 34, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
