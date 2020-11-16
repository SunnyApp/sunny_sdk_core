import 'package:intl/intl.dart';
import 'package:sunny_dart/time/date_components.dart';

import 'time_unit.dart';

const months = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};

typedef FlexiDateFormatter = String Function(FlexiDate date,
    {String futureLabel, String historyLabel, bool withYear, String dateLabel});

class FlexiDate extends DateComponents {
  static FlexiDateFormatter fullFormatter = (
    date, {
    String futureLabel = "in",
    String historyLabel = "ago",
    bool withYear = false,
    String dateLabel = "",
  }) {
    return date.formatted();
  };

  FlexiDate({int day, int month = 1, int year})
      : super(day: day, month: month, year: year);

  FlexiDate.fromDateTime(DateTime time)
      : super(day: time.day, month: time.month, year: time.year);

  factory FlexiDate.now() {
    final dateTime = DateTime.now();
    return FlexiDate(
        day: dateTime?.day, month: dateTime?.month, year: dateTime?.year);
  }

  factory FlexiDate.from(input) {
    final dc = DateComponents.from(input);
    return FlexiDate(day: dc?.day, month: dc?.month, year: dc?.year);
  }

  factory FlexiDate.tryFrom(input) {
    final dc = DateComponents.tryFrom(input);
    if (dc == null) return null;
    return FlexiDate(day: dc?.day, month: dc?.month, year: dc?.year);
  }

  factory FlexiDate.fromJson(json) {
    if (json == null) return null;
    return FlexiDate.from(json);
  }

  @override
  FlexiDate withoutDay() => FlexiDate(day: null, month: month, year: year);

  @override
  FlexiDate withoutYear() => FlexiDate(day: day, month: month, year: null);

  String fullFormat({
    String futureLabel = "in",
    String historyLabel = "ago",
    bool withYear = false,
    String dateLabel = "",
  }) {
    return fullFormatter?.call(this,
        futureLabel: futureLabel,
        historyLabel: historyLabel,
        withYear: withYear,
        dateLabel: dateLabel);
  }
}

extension DateComponentsFormat on DateComponents {
  String formatted() => formatFlexiDate(this);
}

extension DateTimeToFlexiDateExtensions on DateTime {
  FlexiDate toDate() {
    return FlexiDate(month: this.month, year: this.year, day: this.day);
  }
}

Duration durationOf(TimeUnit timeUnit, int timeAmount) {
  if (timeUnit == null && timeAmount == null) return null;

  switch (timeUnit.value) {
    case "DAYS":
      return Duration(days: timeAmount);
    case "HOURS":
      return Duration(hours: timeAmount);
    case "MINUTES":
      return Duration(minutes: timeAmount);
    case "SECONDS":
      return Duration(seconds: timeAmount);
    case "MILLISECONDS":
      return Duration(milliseconds: timeAmount);
    case "MICROSECONDS":
      return Duration(microseconds: timeAmount);
    default:
      throw Exception("Unable to convert from $timeUnit units");
  }
}

String formatFlexiDate(
  input, {
  bool withYear = true,
  bool withMonth = true,
  bool withDay = true,
}) {
  final flexi =
      input is FlexiDate ? input : FlexiDate.tryFrom(input?.toString());
  if (flexi == null) {
    return null;
  }
  String result = "";
  final date = flexi.toDateTime();
  if (flexi.hasMonth && withMonth != false) {
    result += "${DateFormat.MMM().format(date)} ";
    if (flexi.hasDay && withDay != false) {
      result += "${DateFormat.d().format(date)}";
    }
  }
  result = result.trim();
  if (flexi.hasYear && withYear != false) {
    if (flexi.hasMonth && flexi.hasDay) result += ",";
    if (result.isNotEmpty) result += " ";
    result += "${DateFormat.y().format(date)}";
  }
  return result;
}
