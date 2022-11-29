import 'dart:async';

import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/model_exports.dart';
import 'package:sunny_sdk_core/sunny_sdk_core.dart';

typedef RecordLoader<RType, KType> = Future<RType> Function(KType id);
typedef KeyMapper<RType, KType> = KType Function(RType input);

class StreamChange<RType> {
  final bool isLoad;
  final RType? record;

  StreamChange(this.isLoad, this.record);
}

abstract class RecordDataService<RType, KType> with LifecycleAwareMixin {
  final _recordStreams = <KType, DataService<RType>>{};

  /// This stream contains updates only - no loads
  final _allChangeStream = StreamController<StreamChange<RType>>.broadcast();

  final bool isLazy;
  final bool resetOnLogout;

  RecordDataService({this.resetOnLogout = true, this.isLazy = false});

  factory RecordDataService.of(
          {required KeyMapper<RType, KType> idMapper,
          required RecordLoader<RType, KType> loader}) =>
      _RecordDataService(idMapper, loader);

  /// Retrieves the latest copy of the data from an external source
  @protected
  Future<RType> internalFetchRecord(KType id);

  /// Returns the key that will be used to key the results
  @protected
  KType getIdForRecord(RType record);

  void addToStream(RType? record, {bool isLoad = false, bool silent = false}) {
    exec(() {
      if (record != null) {
        final id = getIdForRecord(record);
        final _recordStream = _getOrCreateStream(id);
        if (silent) {
          _recordStream.updateQuiet(record);
        } else {
          _recordStream.currentValue = record;
          _allChangeStream.add(StreamChange(isLoad, record));
        }
      }
    });
  }

  Future updateRecord(KType id, Future update(RType? record),
      {bool silent = false}) {
    return exec(() async {
      final latest = await getRecord(id);
      final res = await update(latest);
      if (res is RType) {
        addToStream(res, silent: silent);
      } else {
        addToStream(latest, silent: silent);
      }
    });
  }

  @protected
  @override
  Future doShutdown() async {
    for (final e in _recordStreams.entries) {
      await e.value.dispose();
    }
    _allChangeStream.close();
  }

  /// @param: immediate Whether you want this stream to include the current value.  If false, only updates will be streamed.
  Stream<RType?>? recordStream(KType recordId, {bool immediate = true}) {
    return exec(() {
      return immediate
          ? _getOrCreateStream(recordId).stream.asBroadcastStream()
          : _getOrCreateStream(recordId).updateStream.asBroadcastStream();
    });
  }

  Stream<RType> get changeStream {
    if (isShuttingDown()) {
      return Stream.empty();
    } else {
      return _allChangeStream.stream
          .where((r) => !r.isLoad && r.record != null)
          .map((r) => r.record!);
    }
  }

  /// Returns all changes/loads
  /// use [changeStream] if you only want updates
  Stream<RType> get dataStream {
    if (isShuttingDown()) {
      return Stream.empty();
    } else {
      return _allChangeStream.stream.map((r) => r.record!);
    }
  }

  Future<RType?> getRecord(KType recordId) async {
    if (recordId == null) {
      log.warning("Null recordId passed for $RType");
      return null;
    }
    final s = _getOrCreateStream(recordId);
    final got = await s.get();
    return got;
  }

  RType? tryGet(KType recordId) {
    if (recordId == null) return null;
    var s = _getOrCreateStream(recordId);
    return s.currentValue;
  }

  Iterable<RType> get loadedRecords {
    final copy = [
      ..._recordStreams.values.map((_) => _.currentValue).whereNotNull(),
    ];
    return copy.cast();
  }

  @override
  Stream<AuthUserProfile> get userStateStream =>
      sunny.get<IAuthState>().userStateStream;

  DataService<RType>? tryGetService(KType recordId) {
    return _recordStreams[recordId];
  }

  @protected
  DataService<RType>? getService(KType recordId) {
    return _recordStreams[recordId];
  }

  Future<RType>? refreshRecord(KType recordId) {
    return exec(() => getService(recordId)!.refresh());
  }

  Future<RType>? tryRefreshRecord(KType recordId) {
    return exec((() => tryGetService(recordId)?.refresh()));
  }

  bool isLoaded(KType recordId) {
    return _recordStreams.containsKey(recordId);
  }

  bool isInitialized(KType recordId) {
    final record = _recordStreams[recordId];
    if (record == null) {
      return false;
    } else {
      return record.isReady.isCompleted;
    }
  }

  DataService<RType> _getOrCreateStream(KType recordId) {
    if (recordId == null) {
      log.warning("Null ID for $RType is bad", "Error", StackTrace.current);
      return nullDataService();
    }
    return _recordStreams.putIfAbsent(
      recordId,
      () {
        final KType outerRecordId = recordId;
        return DataService.of(
          isLazy: isLazy,
          resetOnLogout: resetOnLogout,
          factory: () async {
            log.info("Fetching $RType with id: $outerRecordId");
            final RType loaded = await this.internalFetchRecord(outerRecordId);
            addToStream(loaded, isLoad: true);
            return loaded;
          },
        );
      },
    );
  }
}

T? _null<T>() => null;

DataService<T> nullDataService<T>() =>
    DataService.of(factory: _null as Future<T> Function());

/// Default implementation that uses closures to implement
class _RecordDataService<RType, KType> extends RecordDataService<RType, KType>
    with LoggingMixin {
  final KeyMapper<RType, KType> idMapper;
  final RecordLoader<RType, KType> loader;

  @override
  KType getIdForRecord(RType record) {
    return idMapper(record);
  }

  @override
  Future<RType> internalFetchRecord(KType id) {
    return loader(id);
  }

  _RecordDataService(this.idMapper, this.loader) : super();
}

/// Can be used to apply the delegate pattern in cases where inheritance doesn't make sense.
mixin RecordDataServiceMixin<RType, KType>
    implements RecordDataService<RType, KType> {
  RecordDataService<RType, KType> get delegate;

  @override
  Future<RType>? refreshRecord(KType recordId) =>
      delegate.refreshRecord(recordId);

  @override
  Future<RType>? tryRefreshRecord(KType recordId) =>
      delegate.tryRefreshRecord(recordId);

  Iterable<RType> get loadedRecords => delegate.loadedRecords;

  Future updateRecord(KType id, Future update(RType? record),
          {bool silent = false}) =>
      delegate.updateRecord(id, update, silent: silent);

  @override
  DataService<RType>? tryGetService(KType recordId) =>
      delegate.tryGetService(recordId);

  @override
  bool isLoaded(KType recordId) => delegate.isLoaded(recordId);

  @override
  bool isInitialized(KType recordId) => delegate.isInitialized(recordId);

  @override
  void addToStream(RType? record, {bool isLoad = false, bool silent = false}) =>
      delegate.addToStream(record, isLoad: isLoad, silent: silent);

  @override
  Stream<RType> get changeStream => delegate.changeStream;

  @override
  KType getIdForRecord(RType record) => delegate.getIdForRecord(record);

  @override
  DataService<RType>? getService(KType recordId) =>
      delegate.getService(recordId);

  @override
  Future<RType> internalFetchRecord(KType id) =>
      delegate.internalFetchRecord(id);

  @override
  RType? tryGet(KType recordId) => delegate.tryGet(recordId);

  @override
  Stream<RType?>? recordStream(KType recordId, {bool immediate = true}) =>
      delegate.recordStream(recordId, immediate: true);

  @override
  Future<RType?> getRecord(KType recordId) => delegate.getRecord(recordId);

  Stream<RType> get dataStream => delegate.dataStream;
  bool get isLazy => delegate.isLazy;
  bool get resetOnLogout => delegate.resetOnLogout;
}

extension RecordDateServiceUpdate<RType, KType>
    on RecordDataService<RType, KType> {
  FutureOr<RType?> getRecordOr(KType recordId) {
    if (this.isInitialized(recordId)) {
      return tryGet(recordId);
    } else {
      return getRecord(recordId);
    }
  }

  Future<bool>? tryUpdateRecord(KType recordId, Future update(RType? input)) {
    return exec(() async {
      final svc = tryGetService(recordId);
      if (svc?.currentValue == null) {
        return false;
      } else {
        var currValue = svc!.currentValue;
        final res = await update(currValue);
        if (res is RType) {
          svc.currentValue = res;

          /// Adds it to the outer stream
          addToStream(res);
        } else {
          svc.currentValue = currValue;

          /// Adds it to the outer stream
          addToStream(currValue);
        }
        return true;
      }
    });
  }
}
