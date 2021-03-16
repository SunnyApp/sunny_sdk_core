import 'package:dartxx/dartxx.dart';
import 'package:flexidate/flexidate.dart';
import 'package:intl/intl.dart';

import 'time_unit.dart';

const months = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};

typedef FlexiDateFormatter = String Function(FlexiDate date,
    {String? futureLabel,
    String? historyLabel,
    bool? withYear,
    String? dateLabel});

class FlexiDate2 extends FlexiDateData {
  static FlexiDateFormatter fullFormatter = (
    date, {
    String? futureLabel = "in",
    String? historyLabel = "ago",
    bool? withYear = false,
    String? dateLabel = "",
  }) {
    return date.formatted() ?? '';
  };

  FlexiDate2({int? day, int? month = 1, int? year})
      : super(day: day, month: month, year: year);

  FlexiDate2.fromDateTime(DateTime time)
      : super(day: time.day, month: time.month, year: time.year);

  factory FlexiDate2.now() {
    final dateTime = DateTime.now();
    return FlexiDate2(
        day: dateTime.day, month: dateTime.month, year: dateTime.year);
  }

  static FlexiDate2? from(input) {
    final dc = FlexiDate.from(input);
    return FlexiDate2(day: dc?.day, month: dc?.month, year: dc?.year);
  }

  static FlexiDate? tryFrom(input) {
    final dc = FlexiDate.tryFrom(input);
    if (dc == null) return null;
    return FlexiDate2(day: dc.day, month: dc.month, year: dc.year);
  }

  static FlexiDate2? fromJson(json) {
    if (json == null) return null;
    return FlexiDate2.from(json);
  }

  @override
  FlexiDate withoutDay() => FlexiDate2(day: null, month: month, year: year);

  @override
  FlexiDate withoutYear() => FlexiDate2(day: day, month: month, year: null);

  String fullFormat({
    String futureLabel = "in",
    String historyLabel = "ago",
    bool withYear = false,
    String dateLabel = "",
  }) {
    return fullFormatter.call(this,
        futureLabel: futureLabel,
        historyLabel: historyLabel,
        withYear: withYear,
        dateLabel: dateLabel);
  }
}

extension DateComponentsFormat on FlexiDate {
  String? formatted() => formatFlexiDate(this);

  DateTime toDateTime() {
    final without = DateTime.now().withoutTime();

    return DateTime(
        year ?? without.year, month ?? without.month, day ?? without.day);
  }
}

extension DateTimeToFlexiDateExtensions on DateTime {
  FlexiDate toDate() {
    return FlexiDate2(month: this.month, year: this.year, day: this.day);
  }
}

Duration? durationOf(final TimeUnit? timeUnit, int? timeAmount) {
  if (timeUnit == null && timeAmount == null) {
    return null;
  } else {
    timeAmount ??= 1;
    switch (timeUnit?.value) {
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
}

String? formatFlexiDate(
  input, {
  bool withYear = true,
  bool withMonth = true,
  bool withDay = true,
}) {
  final flexi =
      input is FlexiDate2 ? input : FlexiDate2.tryFrom(input?.toString());
  if (flexi == null) {
    return null;
  }
  String result = "";
  final date = flexi.toDateTime();
  if (flexi.month != null && withMonth != false) {
    result += "${DateFormat.MMM().format(date)} ";
    if (flexi.day != null && withDay != false) {
      result += "${DateFormat.d().format(date)}";
    }
  }
  result = result.trim();
  if (flexi.month != null && withYear != false) {
    if (flexi.month != null && flexi.day != null) result += ",";
    if (result.isNotEmpty) result += " ";
    result += "${DateFormat.y().format(date)}";
  }
  return result;
}
