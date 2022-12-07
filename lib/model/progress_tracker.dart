import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:sunny_dart/sunny_dart.dart';

class ProgressTracker<T> extends ChangeNotifier {
  ProgressTracker._(FutureOr<num> total, [Object? key])
      : key = key,
        _total = total.resolveOrNull()?.toDouble() {
    total.futureValue().then((total) {
      this._total = total.toDouble();
      updateTotal(total.toDouble());
    });
  }

  final SafeCompleter<T> _completer = SafeCompleter<T>();

  /// Creates
  ProgressTracker(FutureOr<num> total, Object key) : this._(total, key);

  /// Instead of counting towards an arbitrary count, we'll base the counter on a percent and the caller will
  /// make sure to send the appropriate ratios
  ProgressTracker.ratio([Object? key]) : this._(100.0, key);

  /// The total number of units working towards.  For percent/ratio based tracking, this will be 100
  double? _total = 0.0;

  final Object? key;

  double _progress = 0.0;

  double get progress => _progress;

  String? get task => _task;

  /// Stores what's currently being worked on
  String? _task;

  /// The total number of units working towards.  For percent/ratio based tracking, this will be 100
  double? get total => _total;

  bool get isInProgress => _progress < _total!;

  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  void updateTotal(double total) {
    if (total != _total) {
      _total = total;
      this.notifyListeners();
    }
  }

  Future<T> get result => _completer.future;

  Timer? _timer;

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      super.dispose();
    }
  }

  void finishTask(double progress, {String? newTask}) {
    update(progress, newTask: newTask);
  }

  ///
  /// Updates towards a certain value by half of the remaining each period
  void updateTowards(double progress,
      {String? newTask,
      double? total,
      Duration duration = const Duration(milliseconds: 750)}) {
    _timer?.cancel();
    _timer = Timer.periodic(duration, (timer) {
      var nextAmount = (this.progress - progress) / 2;
      update(nextAmount, newTask: newTask, total: total, clearTimer: false);
    });
  }

  void update(double progress,
      {String? newTask, double? total, bool clearTimer = true}) {
    if (clearTimer && _timer != null) {
      _timer!.cancel();
    }
    bool isDifferent =
        this.progress != progress || (newTask != null && newTask != this.task);
    if (total != null) {
      _total = total;
    }
    this._progress = progress;
    if (newTask != null) {
      this._task = newTask;
    }

    if (isDifferent) {
      notifyListeners();
    }
  }

  void updateRatio(double ratio, {String? newTask}) {
    assert(ratio >= 0 && ratio <= 1);
    final ratioAmount = 100 * ratio;
    update(ratioAmount, newTask: newTask);
  }

  void decrement() {
    update(progress - 1.0);
  }

  void increment([double amount = 1.0]) {
    update(progress + amount);
  }

  void reset() {
    update(0.0);
  }

  void finishTaskRatio(double progress, {String? newTask}) {
    updateRatio(progress, newTask: newTask);
  }

  void updateTask(String newTask) {
    if (newTask != this.task) {
      this._task = newTask;
      this.notifyListeners();
    }
  }

  /// Returns a percent completed, between 0 and 100
  double get percent {
    if (_total == 0) return 0;
    return math.min(1, math.max(0, progress / _total!));
  }

  /// Returns the completed percent in textual form, with a % sign
  String get percentText => "${(percent * 100).round()}%";

  /// Marks this counter as complete
  void complete([T? result]) {
    update(_total!.toDouble());
    _completer.complete(result);
  }

  /// Marks this counter as complete
  void completeError([Object? error, StackTrace? stack]) {
    update(_total!.toDouble());
    _completer.completeError(error ?? "There was an error", stack);
  }
}
