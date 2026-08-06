import 'dart:developer' as dev;

class Helpers {
  Helpers._();

  static void log(String message, {String name = 'SydFlow'}) {
    dev.log(message, name: name);
  }

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
