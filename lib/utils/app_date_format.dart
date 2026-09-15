// lib/utils/app_date_format.dart
//
// The one place in the app allowed to construct a DateFormat for availability
// / appointment / booking screens (QA BUG-6). Everywhere the backend already
// sends a `*Label` string, print that directly instead of calling this —
// these are only a fallback for the few spots the server hasn't labelled.
import 'package:intl/intl.dart';

class AppDateFormat {
  AppDateFormat._();

  // Canonical patterns from the backend's `dateFormat` block.
  static final DateFormat _date = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _dateShort = DateFormat('d MMM yyyy');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _dateTime = DateFormat('EEE, d MMM yyyy, h:mm a');
  static const String rangeSeparator = '–';

  static String date(DateTime value) => _date.format(value);
  static String dateShort(DateTime value) => _dateShort.format(value);
  static String time(DateTime value) => _time.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);

  static String range(DateTime start, DateTime end) =>
      '${_time.format(start)} $rangeSeparator ${_time.format(end)}';

  // For a raw "HH:mm" string (no DateTime available).
  static String timeOfDay(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return hhmm;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return hhmm;
    return _time.format(DateTime(2000, 1, 1, hour, minute));
  }

  static String rangeOfDay(String startHHmm, String endHHmm) =>
      '${timeOfDay(startHHmm)} $rangeSeparator ${timeOfDay(endHHmm)}';
}
