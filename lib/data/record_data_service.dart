import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/services/lifecycle_aware.dart';
import 'package:sunny_sdk_core/sunny_sdk_core.dart';

import 'data_service.dart';

typedef RecordLoader<T> = Future<T> Function(String id);
typedef KeyMapper<T> = String Function(T input);

abstract class RecordDataService<T> with LifecycleAwareMixin {
  final _recordStreams = <String, DataService<T>>{};

  /// This stream contains updates only - no loads
  final _changeStream = StreamController<T>.broadcast();

  RecordDataService();

  factory RecordDataService.of(
          {KeyMapper<T> idMapper, RecordLoader<T> loader}) =>
      _RecordDataService(idMapper, loader);

  /// Retrieves the latest copy of the data from an external source
  @protected
  Future<T> internalFetchRecord(String id);

  /// Returns the key that will be used to key the results
  @protected
  String getIdForRecord(T record);

  void addToStream(T record) {
    exec(() {
      if (record != null) {
        final id = getIdForRecord(record);
        _getOrCreateStream(id).currentValue = record;
        _changeStream.add(record);
      }
    });
  }

  void updateRecord(String id, Future update(T record)) {
    exec(() async {
      final latest = await getRecord(id);
      final res = await update(latest);
      if (res is T) {
        addToStream(res);
      } else {
        addToStream(latest);
      }
    });
  }

  @protected
  @override
  Future doShutdown() async {
    for (final e in _recordStreams.entries) {
      await e.value.dispose();
    }
    _changeStream.close();
  }

  Stream<T> recordStream(String recordId) {
    return exec(() {
      return _getOrCreateStream(recordId).stream;
    });
  }

  Stream<T> get changeStream {
    if (!isShuttingDown()) {
      return Stream.empty();
    } else {
      return _changeStream.stream;
    }
  }

  Future<T> getRecord(String recordId) async {
    if (recordId == null) {
      log.warning("Null recordId passed for $T");
      return null;
    }
    final s = _getOrCreateStream(recordId);
    final got = await s.get();
    return got;
  }

  T tryGet(String recordId) {
    if (recordId == null) return null;
    var s = _getOrCreateStream(recordId);
    return s.currentValue;
  }

  Iterable<T> get loadedRecords {
    final copy = [
      ..._recordStreams.values
          .map((_) => _.currentValue)
          .where((_) => _ != null)
    ];
    return copy;
  }

  @override
  Stream<AuthUserProfile> get userStateStream =>
      Sunny.get<IAuthState>().userStateStream;

  DataService<T> tryGetService(String recordId) {
    return _recordStreams[recordId];
  }

  @protected
  DataService<T> getService(String recordId) {
    return _recordStreams[recordId];
  }

  Future<T> refreshRecord(String recordId) {
    return exec(() => getService(recordId).refresh());
  }

  Future<T> tryRefreshRecord(String recordId) {
    return exec(() => tryGetService(recordId)?.refresh());
  }

  bool isLoaded(String recordId) {
    return _recordStreams.containsKey(recordId);
  }

  DataService<T> _getOrCreateStream(String recordId) {
    if (recordId == null) {
      log.warning("Null ID for $T is bad", "Error", StackTrace.current);
      return nullDataService();
    }
    return _recordStreams.putIfAbsent(
      recordId,
      () {
        final outerRecordId = recordId;
        return DataService.of(
          factory: () async {
            log.info("Fetching $T with id: $outerRecordId");
            final loaded = await this.internalFetchRecord(outerRecordId);
            return loaded;
          },
        );
      },
    );
  }
}

T _null<T>() => null;
DataService<T> nullDataService<T>() => DataService.of(factory: _null);

/// Default implementation that uses closures to implement
class _RecordDataService<T> extends RecordDataService<T> with LoggingMixin {
  final KeyMapper<T> idMapper;
  final RecordLoader<T> loader;

  @override
  String getIdForRecord(T record) {
    return idMapper(record);
  }

  @override
  Future<T> internalFetchRecord(String id) {
    return loader(id);
  }

  _RecordDataService(this.idMapper, this.loader)
      : assert(idMapper != null),
        assert(loader != null);
}

/// Can be used to apply the delegate pattern in cases where inheritance doesn't make sense.
mixin RecordDataServiceMixin<T> implements RecordDataService<T> {
  RecordDataService<T> get delegate;

  @override
  Future<T> refreshRecord(String recordId) => delegate.refreshRecord(recordId);

  @override
  Future<T> tryRefreshRecord(String recordId) =>
      delegate.tryRefreshRecord(recordId);

  Iterable<T> get loadedRecords => delegate.loadedRecords;

  void updateRecord(String id, Future update(T record)) =>
      delegate.updateRecord(id, update);

  @override
  DataService<T> tryGetService(String recordId) =>
      delegate.tryGetService(recordId);

  @override
  bool isLoaded(String recordId) => delegate.isLoaded(recordId);

  @override
  void addToStream(T record) => delegate.addToStream(record);

  @override
  Stream<T> get changeStream => delegate.changeStream;

  @override
  String getIdForRecord(T record) => delegate.getIdForRecord(record);

  @override
  DataService<T> getService(String recordId) => delegate.getService(recordId);

  @override
  Future<T> internalFetchRecord(String id) => delegate.internalFetchRecord(id);

  @override
  T tryGet(String recordId) => delegate.tryGet(recordId);

  @override
  Stream<T> recordStream(String recordId) => delegate.recordStream(recordId);

  @override
  Future<T> getRecord(String recordId) => delegate.getRecord(recordId);
}
