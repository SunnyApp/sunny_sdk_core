import 'package:flexidate/flexible_date.dart';
import 'package:intl/intl.dart';
import 'package:sunny_dart/i18n.dart';
import 'package:timezone/timezone.dart';

final isoDateFormat = DateFormat("yyyy-MM-dd");

TZDateTime tzDateTime(DateTime dateTime) => dateTime is TZDateTime
    ? dateTime
    : TZDateTime.from(dateTime, sunnyLocalization.userLocation!);

String? smartDateFormat(DateTime? dateTime,
    {bool? formatTime, bool useToday = true}) {
  if (dateTime == null) return null;

  formatTime ??= hasTime(dateTime);
  TZDateTime tzToFormat = tzDateTime(dateTime);
  if (!formatTime) {
    final now = TZDateTime.now(tzToFormat.location);
    final date = tzToFormat;
    if (now.day == date.day && useToday == true) {
      // Same day
      return "today";
    } else if (now.year == date.year) {
      return dateFormatNoYear.format(date);
    } else {
      return dateFormatWithYear.format(date);
    }
  } else {
    return smartDateTimeFormat(tzToFormat);
  }
}

String smartDateTimeFormat(DateTime dateTime) {
  final TZDateTime toFormat = tzDateTime(dateTime);
  final now = TZDateTime.now(toFormat.location);
  final date = toFormat.toLocal();

  if (now.day == date.day) {
    return formatDateTimeSameDay(date);
  } else if (now.year == date.year) {
    return formatDateTimeSameYear(date);
  } else {
    return formatDateTimeWithYear(date);
  }
}

final dateFormatWithYear = DateFormat("MMM d, yyyy");
final dateFormatNoYear = DateFormat("EEE, MMM d");
final dateFormatMonthDay = DateFormat("MMM d");
final monthYear = DateFormat("MMM yyyy");

String formatDateTimeWithYear(TZDateTime dateTime) =>
    _withLocation(_dateTimeFormatWithYear, dateTime);

String formatDateTimeSameYear(TZDateTime dateTime) =>
    _withLocation(_dateTimeFormatSameYear, dateTime);

String formatDateTimeSameDay(TZDateTime dateTime) =>
    _withLocation(_dateTimeFormatSameDay, dateTime);

String _withLocation(DateFormat format, TZDateTime toFormat) {
  // To format it properly, we need to convert it to a local time
  toFormat.toLocal();
  return format.format(toFormat) + " " + toFormat.location.currentTimeZone.abbr;
}

final _dateTimeFormatWithYear = DateFormat("MMM d, yyyy 'at' h:mma");
final _dateTimeFormatSameYear = DateFormat("EEE, MMM d 'at' h:mma");
final _dateTimeFormatSameDay = DateFormat("'today at 'h:mm a");
