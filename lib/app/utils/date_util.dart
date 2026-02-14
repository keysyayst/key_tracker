import 'package:intl/intl.dart';

class DateUtil {
  static String yMd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
