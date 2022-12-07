import 'dart:async';

import 'package:sunny_dart/sunny_dart.dart';

abstract class Result<T> {
  T get value;

  ResultType get resultType;

  String? get message;

  factory Result.success(T result, [String? message]) {
//    assert(result != null);
    return _Result(result, ResultType.success, message);
  }

  factory Result.dismissed(T result, [String? message]) {
    assert(result != null);
    return _Result(result, ResultType.skipped, message);
  }

  static Result<T?> error<T>(String message) {
    return _Result<T?>(null, ResultType.error, message);
  }

  static Result<T?> noop<T>() {
    return _Result<T?>(null, ResultType.cancelled, null);
  }

  Result<T> withMessage(String message);

  static Future<TimedResult<T?>> timed<T>(FutureOr<T> exec,
      {String? debugName}) async {
    final start = DateTime.now();
    final value = await exec;
    try {
      return TimedResult<T>(value, ResultType.success, null, start.sinceNow(),
          debugName: debugName);
    } catch (e) {
      return TimedResult<T?>(null, ResultType.error, "$e", start.sinceNow(),
          debugName: debugName);
    }
  }
}

class TimedResult<T> extends _Result<T> {
  final String? debugName;
  final Duration duration;

  @override
  Result<T> withMessage(String message) {
    return TimedResult(value, resultType, message, duration,
        debugName: debugName);
  }

  TimedResult(T value, ResultType resultType, String? message, this.duration,
      {this.debugName})
      : super(value, resultType, message);
}

enum ResultType { success, error, cancelled, skipped }

class _Result<T> implements Result<T> {
  final T value;
  final ResultType resultType;
  final String? message;

  @override
  Result<T> withMessage(String message) {
    return _Result(value, resultType, message);
  }

  const _Result(this.value, this.resultType, this.message);

  @override
  String toString() {
    var str = 'Result{ type: $resultType, ';
    if (value != null) str += "value: $value, ";
    if (message != null) str += "message: $message, ";
    str += ' }';
    return str;
  }
}

extension ResultExtension on Result? {
  bool get isSuccessful =>
      this == null ? true : this!.resultType == ResultType.success;

  bool get isError =>
      this == null ? false : this!.resultType == ResultType.error;

  bool get isSkipped =>
      this == null ? false : this!.resultType == ResultType.skipped;

  bool get isCancelled =>
      this == null ? false : this!.resultType == ResultType.cancelled;
}
