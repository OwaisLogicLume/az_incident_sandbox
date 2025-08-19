import 'package:intl/intl.dart';

extension DateTimeToString on DateTime {
  String get toddMMYYYYHHMM {
    final formatter = DateFormat('dd/MM/yy hh:mm a');
    return formatter.format(this);
  }
}
