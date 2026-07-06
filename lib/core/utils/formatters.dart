import 'package:intl/intl.dart';

final _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final _dateFormat = DateFormat('d MMM yyyy', 'id_ID');
final _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

String formatRupiah(num value) => _rupiahFormat.format(value);

String formatDate(DateTime value) => _dateFormat.format(value.toLocal());

String formatDateTime(DateTime value) => _dateTimeFormat.format(value.toLocal());
