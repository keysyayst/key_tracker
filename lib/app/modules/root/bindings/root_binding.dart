import 'package:get/get.dart';
import '../controllers/root_controller.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../books/controllers/books_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(RootController(), permanent: true);

    // Controller untuk tab/tabbar (dipakai langsung via widget, bukan via route)
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
    Get.lazyPut<AnalyticsController>(() => AnalyticsController(), fenix: true);
    Get.lazyPut<BooksController>(() => BooksController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
  }
}
