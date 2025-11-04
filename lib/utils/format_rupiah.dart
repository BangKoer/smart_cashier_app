import 'package:intl/intl.dart';

String toRupiah(dynamic amount) {
  final rupiahFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  return rupiahFormatter.format(amount);
}

String formatDouble(double value) {
  if (value == value.toInt()) {
    // Checks if the fractional part is zero
    return value.toInt().toString(); // Displays only the integer part
  } else {
    return value.toString(); // Displays the full double value
  }
}
