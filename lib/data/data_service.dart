import 'dart:async';

import 'package:meta/meta.dart';

import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_dart/helpers/safe_completer.dart';
import 'package:sunny_sdk_core/services.dart';

typedef _AsyncValueGetter<R> = Future<R> Function();

/// Container for data that allows easy subscriptions and rendering
abstract class DataService<T> with LifecycleAwareMixin, LoggingMixin {
  final _updateStream = StreamController<T>.broadcast();
  final SafeCompleter<T> isReady = SafeCompleter.stopped();
  T? _currentValue;
  
  DataService({bool isLazy = false}) {
    if (!isLazy) {
      loadInitial();
    }
    onLogout(() => reset());
  }

  factory DataService.of({required _AsyncValueGetter<T> factory}) => _DataService(factory);

  @protected
  Future<T> loadInitial() {
    isReady.start();

    return internalFetchData().then((data) {
      this._internalUpdate(data);
      return data;
    }).catchError((Object e, StackTrace stack) {
      log.severe("Error fetching data for service: $e", e, stack);
      isReady.completeError(e, stack);
      throw e;
    });
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
    if (!controller.isClosed) controller.add(null);
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

  _DataService(this._internalFetchData) : super();
}
