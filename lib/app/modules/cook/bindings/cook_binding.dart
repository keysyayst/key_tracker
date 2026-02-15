import 'package:get/get.dart';
import '../controllers/cook_controller.dart';

class CookBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CookController());
  }
}
