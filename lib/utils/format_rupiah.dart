import 'package:intl/intl.dart';

  String toRupiah(dynamic amount) {
    final rupiahFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return rupiahFormatter.format(amount);
  }