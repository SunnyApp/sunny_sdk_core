import 'dart:convert';

import 'package:sunny_dart/json.dart';

class TimeUnit extends TimeUnitBase {
  const TimeUnit._internal(String value) : super._internal(value);

  const TimeUnit.unknown(String value) : super.unknown(value);

  // ignore: non_constant_identifier_names
  static const TimeUnit nanos_ = TimeUnit._internal("NANOS");

  // ignore: non_constant_identifier_names
  static const TimeUnit micros_ = TimeUnit._internal("MICROS");

  // ignore: non_constant_identifier_names
  static const TimeUnit millis_ = TimeUnit._internal("MILLIS");

  // ignore: non_constant_identifier_names
  static const TimeUnit seconds_ = TimeUnit._internal("SECONDS");

  // ignore: non_constant_identifier_names
  static const TimeUnit minutes_ = TimeUnit._internal("MINUTES");

  // ignore: non_constant_identifier_names
  static const TimeUnit hours_ = TimeUnit._internal("HOURS");

  // ignore: non_constant_identifier_names
  static const TimeUnit days_ = TimeUnit._internal("DAYS");

  // ignore: non_constant_identifier_names
  static const TimeUnit weeks_ = TimeUnit._internal("WEEKS");

  // ignore: non_constant_identifier_names
  static const TimeUnit months_ = TimeUnit._internal("MONTHS");

  // ignore: non_constant_identifier_names
  static const TimeUnit years_ = TimeUnit._internal("YEARS");

  static TimeUnit fromJson(dynamic data) {
    if (data == null) return null;
    switch ("$data") {
      case "NANOS":
        return TimeUnit.nanos_;
      case "MICROS":
        return TimeUnit.micros_;
      case "MILLIS":
        return TimeUnit.millis_;
      case "SECONDS":
        return TimeUnit.seconds_;
      case "MINUTES":
        return TimeUnit.minutes_;
      case "HOURS":
        return TimeUnit.hours_;
      case "DAYS":
        return TimeUnit.days_;
      case "WEEKS":
        return TimeUnit.weeks_;
      case "MONTHS":
        return TimeUnit.months_;
      case "YEARS":
        return TimeUnit.years_;
      default:
        return TimeUnit.unknown("$data");
    }
  }

  static List<TimeUnit> values = [
    TimeUnit.nanos_,
    TimeUnit.micros_,
    TimeUnit.millis_,
    TimeUnit.seconds_,
    TimeUnit.minutes_,
    TimeUnit.hours_,
    TimeUnit.days_,
    TimeUnit.weeks_,
    TimeUnit.months_,
    TimeUnit.years_
  ];

  static dynamic encode(TimeUnit data) => data.value;

  dynamic toJson() => json.encode(value);
}

class TimeUnitBase extends MLiteral<String> {
  final bool isKnown;

  const TimeUnitBase._internal(String value)
      : isKnown = true,
        super(value);

  const TimeUnitBase.unknown(String value)
      : isKnown = false,
        super(value);
}
