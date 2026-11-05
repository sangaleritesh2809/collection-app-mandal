import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatCurrency(num amount) {
    return _currencyFormat.format(amount);
  }

  static String formatDate(dynamic date) {
    if (date == null) return '-';
    if (date is String) {
      try {
        return _dateFormat.format(DateTime.parse(date));
      } catch (_) {
        return date;
      }
    }
    if (date is DateTime) {
      return _dateFormat.format(date);
    }
    return '-';
  }

  static String formatDateTime(dynamic date) {
    if (date == null) return '-';
    if (date is String) {
      try {
        return _dateTimeFormat.format(DateTime.parse(date).toLocal());
      } catch (_) {
        return date;
      }
    }
    if (date is DateTime) {
      return _dateTimeFormat.format(date.toLocal());
    }
    return '-';
  }

  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '-';
    if (phone.length == 10) {
      return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }
}

