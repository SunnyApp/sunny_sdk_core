import 'dart:async';

import 'package:dartxx/dartxx.dart';
import 'package:meta/meta.dart';

import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_dart/helpers/safe_completer.dart';
import 'package:sunny_sdk_core/services.dart';

typedef _AsyncValueGetter<R> = Future<R> Function();

const _kMaxRetries = 15;

/// Container for data that allows easy subscriptions and rendering
abstract class DataService<T> with LifecycleAwareMixin, LoggingMixin {
  final _updateStream = StreamController<T>.broadcast();
  final SafeCompleter<T> isReady = SafeCompleter.stopped();
  T? _currentValue;
  var _errorCount = 0;

  DataService({bool isLazy = false, bool resetOnLogout = true}) {
    if (!isLazy) {
      loadInitial();
    }
    if (resetOnLogout == true)
      onLogout(() {
        reset();
      });
  }

  factory DataService.of(
          {required _AsyncValueGetter<T> factory,
          bool isLazy = false,
          bool resetOnLogout = true}) =>
      _DataService(
        factory,
        isLazy: isLazy,
        resetOnLogout: resetOnLogout,
      );

  @protected
  Future<T> loadInitial() {
    isReady.start();

    return internalFetchData().then((data) {
      this._internalUpdate(data);
      if (_errorCount > 0) {
        log.warning('Record fetched after failing $_errorCount times');
        _errorCount = 0;
      }

      return data;
    }).catchError((Object e, StackTrace stack) {
      log.severe("Error fetching data for service: $e", e, stack);
      if (isReady.isNotStarted) isReady.start();
      isReady.completeError(e, stack);
      this.reset();
      _errorCount++;
      _scheduleRetry();
      throw e;
    });
  }

  _scheduleRetry() {
    if (_errorCount < _kMaxRetries) {
      var duration = Duration(milliseconds: 500 + (100 * (2 ^ _errorCount)));
      Future.delayed(
        duration,
        () {
          if (_errorCount > 0) {
            log.warning(
                'Retry after waiting ${(duration.inMilliseconds / 1000).roundTo(3)} seconds');
            loadInitial();
          }
        },
      );
    } else {
      log.severe('Failed after $_currentValue attempts');
    }
  }

  Stream<T> get updateStream async* {
    await for (final data in _updateStream.stream) {
      yield data;
    }
  }

  Stream<T?> get stream async* {
    if (currentValue == null && isReady.isNotStarted) {
      final initialLoad = await loadInitial();
      yield initialLoad;
    } else if (currentValue == null && isReady.isStarted) {
      try {
        final isReadyResult = await isReady.future;
        yield isReadyResult;
      } catch (e, stack) {
        log.severe("Error fetching data for service: $e", e, stack);
        isReady.completeError(e, stack);
        yield null;
      }
    } else {
      yield currentValue!;
    }

    await for (final data in _updateStream.stream) {
      yield data;
    }
  }

  /// Retrieves the latest copy of the data from an external source
  Future<T> internalFetchData();

  void reset() {
    _currentValue = null;
    isReady..reset();
    try {
      if (!controller.isClosed && T.toString().endsWith('?'))
        controller.add(null);
    } catch (e) {
      log.info('Unable to send a null value to stream: $e');
    }
  }

  @protected
  StreamController<T?> get controller => _updateStream;

  Future<T> refresh() async {
    final result = await internalFetchData();
    currentValue = result;
    return result;
  }

  T? get currentValue {
    return _currentValue;
  }

  set currentValue(T? value) {
    this._internalUpdate(value);
    if (value != null) {
      if (!controller.isClosed) controller.add(value);
    }
  }

  /// Updates without pushing the new value to the stream
  void updateQuiet(T? value) {
    this._internalUpdate(value);
  }

  T? _internalUpdate(T? value) {
    if (value != null) {
      _currentValue = value;
      if (!isReady.isStarted) isReady.start();
      if (isReady.isNotComplete) isReady.complete(value);
    }
    return _currentValue;
  }

  @protected
  @override
  Future doShutdown() {
    return _updateStream.close();
  }

  /// Retrieves the current copy of this data, if it exists, or fetches it.
  Future<T?> get() {
    if (_currentValue != null) {
      return Future.value(_currentValue);
    } else {
      try {
        if (isReady.isStarted) {
          return isReady.future;
        } else {
          return loadInitial().timeout(Duration(seconds: 10));
        }
      } on TimeoutException catch (e, stack) {
        log.severe("Timeout fetching $T in ${this.runtimeType}", e, stack);
        rethrow;
      }
    }
  }
}

class _DataService<T> extends DataService<T> {
  final _AsyncValueGetter<T> _internalFetchData;

  @override
  Future<T> internalFetchData() {
    return _internalFetchData();
  }

  _DataService(
    this._internalFetchData, {
    bool isLazy = false,
    bool resetOnLogout = true,
  }) : super(
          isLazy: isLazy,
          resetOnLogout: resetOnLogout,
        );
}
