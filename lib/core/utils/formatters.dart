import 'package:intl/intl.dart';
import 'package:subsaver/core/constants/app_constants.dart';

class CurrencyFormatter {
  static String format(double amount, {String symbol = AppConstants.currencySymbol}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    );
    return formatter.format(amount);
  }
}

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff <= 7) return 'In $diff days';
    return formatDate(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }
}
