import 'dart:async';
import 'dart:developer' hide log;

import 'package:collection_diff/map_diff.dart';
import 'package:collection_diff/set_diff.dart';
import 'package:collection_diff_worker/collection_diff_worker.dart';
import 'package:flutter/foundation.dart';
import 'package:meta_forms/mverse.dart';
import 'package:mobx/mobx.dart' hide ObservableMap, MapChange, SetChange;
import 'package:observable_collections/observable_collections.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_sdk_core/api/repository.dart';
import 'package:sunny_sdk_core/services/lifecycle_aware.dart';
import 'package:sunny_sdk_core/sunny_sdk_core.dart';
import 'package:synchronized/synchronized.dart';

abstract class SunnyStore<V extends Entity>
    with LoggingMixin
    implements LifecycleAwareBase {
  SunnyStore(Repository<V> repository, MSchemaRef type, IAuthState loginState)
      : this._(repository, type, loginState);

  SunnyStore._(Repository<V> repository, MSchemaRef type, IAuthState loginState)
      : this.__(repository, type, StreamController.broadcast(), loginState);

  // ignore: non_constant_identifier_names
  SunnyStore.__(this.repository, this.type, this._diffStreamController,
      IAuthState loginState)
      : assert(repository != null),
        assert(type != null),
        assert(_diffStreamController != null),
        _values = _diffStreamController.stream.map((diff) {
          return [...diff.replacement.values];
        }).toSyncStream(
          null,
          null,
          "store.${type.baseCode.replaceAll('.', '_')}.values",
        ) {
    onShutdown(() => clear());

    autoStream(
        () => _reloadRequests.stream.asyncMapSample((bool force) async {
              /// Reload/list requests are debounced so we aren't trying to reload
              /// over the top
              if (isDisabled == true) {
                log.warning("Not reloading because we're disabled");
                return [];
              }
              log.info("Reloading all ${V.name} records (force = $force)");
              if (!_values.isFirstResolved || force) {
                final id = uuid();
                final task = TimelineTask()..start("loadAll$name:$id");
                try {
                  await fetchAll();
                  task.finish();
                } catch (e, stack) {
                  log.severe("Error loading all ${V.simpleName} records: $e", e,
                      stack);
                  task.finish(arguments: {
                    "error": true,
                    "message": "$e",
                  });
                }
              }

              return _values.current;
            }),
        cancelOnError: false);

    this.onLogin(() {
      if (isUserStore) {
        isDisabled = false;
        if (listOnLogin) {
          list();
        }
      }
    });

    this.onLogout(() {
      if (isUserStore) {
        isDisabled = false;
        if (listOnLogin) {
          list();
        }
      }
    });

    registerLoginHooks(loginState);
  }

  /// Allows to temporarily disable, for example until the user logs in
  bool isDisabled = false;

  /// Whether or not this store requires user credentials to operate
  bool get isUserStore;

  bool get clearOnLogout => false;

  bool get listOnLogin => false;

  /// Tracks reload requests and debounces them
  final StreamController<bool> _reloadRequests = StreamController();

  /// Emits each time the complete list is refreshed.
  final StreamController<List<Record<V>>> _reloadCompletions =
      StreamController.broadcast();

  /// Tracks changes to the value list
  SyncStream<List<Record<V>>> _values;

  List<Record<V>> get values => _values.current ?? [];

  Stream<List<Record<V>>> get valuesStream => _values.flatten(const [], false);

  String get loggerName {
    final name = runtimeType.simpleName;
    return name;
  }

  String get name => type.baseCode.replaceAll(".", "_");

  /// Name of the store
  final MSchemaRef type;

  /// The actual data store
  final Map<MKey, ObservableRecord<V>> _data = {};

  @protected
  final Repository<V> repository;

  /// Used to ensure atomic operations
  final _lock = Lock();

  /// Updates the internal map without triggering any persistence.  It's possible that other entities that are
  /// observing this store will update.
  FutureOr<V> put(MKey id, void modification(V _in),
      {bool ignoreNotLoaded = false}) {
    final record = _internalGet(id);
    final modify = record.modify((value) {
      final cloned = repository.clone(value);
      modification(cloned);
      return cloned;
    }, ignoreNotLoaded: ignoreNotLoaded);
    applyChanges((_) => _.change(id, record));
    return modify;
  }

  void putRecord(MKey id, V data) {
    final record = getOrPut(id, data);
    applyChanges((_) => _.set(id, record));
  }

  void removeRecord(MKey id) {
    _data.remove(id);
    applyChanges((_) => _.unset(id));
  }

  @protected
  Record<V> getOrPut(MKey id, [V value]) => runInAction(() {
        return _data.putIfAbsent(id, () => _createRecord(id, value));
      });

  FutureOr<R> applyChanges<R>(
      FutureOr<R> build(MapDiffs<MKey, Record<V>> changes),
      {Map<MKey, Record<V>> replacement}) {
    final starting = {..._data};
    final changes = MapDiffs.builder(starting, replacement: replacement);
    final start = DateTime.now();
    return build(changes).thenOr((result) {
      if (changes.isNotEmpty) {
        log.fine(
            "Applied ${changes.length} changes to $V in ${DateTime.now().difference(start).inMilliseconds}ms");
      }

      /// Some stream combiners don't work unless you emit at least once
      var appliedDiff = MapDiffs<MKey, Record<V>>.ofOperations(
          changes.operations,
          MapDiffArguments(
            starting,
            replacement ?? {..._data},
          ));
      _diffStreamController.add(appliedDiff);
      return result;
    });
  }

  /// Whether the record exists = makes sure the data set is loaded first.
  FutureOr<bool> exists(MKey key) => checked(() => containsKey(key));

  /// Returns the value associated with a key in a map -- this entity is
  /// designed to track any changes to the key from which it originated.
  ///
  /// Make sure to call [disposeAll] when you're done with this.
  Record<V> get(MKey key, [V value]) {
    final currentValue = _internalGet(key, value);
    if (currentValue.isNotLoaded) {
      log.info("Loading missing key $key");
      currentValue.load(
        repository.load(repository.keyToId(key)).then(
          (loaded) async {
            log.info("Load complete for missing key $key");
            final initialized = repository.initialize(loaded);
            await applyChanges((_) => _.change(key, currentValue));
            return initialized;
          },
        ),
      );
      applyChanges((_) => _.set(key, currentValue));
    } else {
      log.finer(
          "Not loading key ${key.mxid}: Resolved: ${currentValue.isResolved}, IsFuture: ${currentValue.isFuture}");
    }

    return currentValue;
  }

  bool get isLoading => !_values.isFirstResolved;

  FutureOr<V> load(MKey key) {
    return get(key).futureOr;
  }

  Future<List<Record<V>>> get nextReload {
    return _reloadCompletions.stream.first;
  }

  Stream<List<Record<V>>> onReload({bool includeCurrentState = true}) {
    if (includeCurrentState == true) {
      return Stream<List<Record<V>>>.fromIterable(
              [_data.values.toList(growable: false)])
          .followedBy(_reloadCompletions.stream);
    } else {
      return _reloadCompletions.stream;
    }
  }

  /// Lists the available data for this store.  If subsequent calls are made, they will resolve to the same future.
  ///
  FutureOr<List<Record<V>>> list({
    /// Whether to force data to load, even if it's already been fetched.  If you want to nuke all the data and refetch,
    /// you need to call [clear], followed by [list]
    bool forceRefresh,
    double offset,
    double limit,
  }) {
    final nextLoad = _reloadCompletions.stream.first;
    if (forceRefresh == true || !_values.isFirstResolved) {
      log.info("$type fetch started");
      _reloadRequests.add(true);
      return nextLoad.then((_) {
        return _;
      });
    }
    return values;
  }

  Stream<MapDiffs<MKey, Record<V>>> get changes => _diffStreamController.stream;

  bool containsKey(MKey key) {
    return _data.containsKey(key);
  }

  /// Executes a function if the full data set is loaded, otherwise,
  /// returns a future
  FutureOr<R> checked<R>(R fn()) {
    if (_values.isFirstResolved) {
      return fn();
    } else {
      return _reloadCompletions.stream.first.then((_) => fn());
    }
  }

  Future<List<Record<V>>> fetchAll({double offset, double limit}) async {
    final loaded = await repository.list(offset: offset, limit: limit);
    await updateAllItems(loaded?.data ?? []);
    return values;
  }

  Future updateAllItems(Iterable<V> data) async {
    final newDataAsMap =
        Map<MKey, V>.fromEntries(data.map(repository.initialize).map((V v) {
      return MapEntry(v.mkey, v);
    }));
    final keyDiffs = await _data.keys.toSet().differencesAsync(
          newDataAsMap.keys.toSet(),
          debugName: "${this.type.baseCode}[keys]",
        );
    await applyChanges((_changes) async {
      runInAction(() {
        /// Handle anything that changed first
        for (final diff in keyDiffs) {
          switch (diff.type) {
            case SetDiffType.add:
              for (final key in diff.items) {
                final _record = _internalGet(key);
                final newRecord = newDataAsMap[key];
                if (_record.isNotLoaded) {
                  _changes.set(key, _record);
                } else {
                  _changes.change(key, _record);
                }
                // Debate on whether this should be silent or not...  A silent update won't publish changes
                // which seems like it could cause issues
                _record.update(newRecord);
              }
              break;
            case SetDiffType.remove:
              for (final key in diff.items) {
                _data.remove(key);
                _changes.unset(key);
              }
              break;
            default:

              /// There aren't any other options for sets
              break;
          }
        }

        /// Do an internal update for all shared keys
        final shared = newDataAsMap.keys.toSet().union(_data.keys.toSet());
        for (final recordId in shared) {
          final _record = _internalGet(recordId);
          final isNew = _record.isNotLoaded;
          final incomingRecord = newDataAsMap[recordId];

          /// If there isn't really any change, then don't bother with an update.
          if (_record.isResolved &&
              !identical(_record.valueOrNull, incomingRecord) &&
              _record.valueOrNull == incomingRecord) {
            log.finer(
                "not propagating record [${recordId.mxid}] because it matches the existing");
            continue;
          }

          _record.update(incomingRecord);

          if (isNew) {
            _changes.set(recordId, _record);
          } else {
            _changes.change(recordId, _record);
          }
        }
      });
    });

    _reloadCompletions.add(_data.values.toList());
  }

  Future<V> create(V input) {
    return createWith((_in) {
      takeFrom(input, _in);
      return _in;
    });
  }

  Future<V> createWith(FutureOr modification(V input)) async {
    return applyChanges((_) async {
      final newRecord = repository.instantiate();
      modification(newRecord);
      final result = await repository.create(newRecord);

      final added = getOrPut(result.mkey, result);
      await afterCreate(result);
      await afterSave(result);
      _.set(result.mkey, added);
      return result;
    });
  }

  Future<V> save(V input) {
    return saveWith(input.mkey, (_in) {
      takeFrom(input, _in);
      return _in;
    });
  }

  Future<bool> delete(V input) async {
    if (_data.containsKey(input.mkey)) {
      _internalGet(input.mkey).update(null, force: true);
    }
    return applyChanges((_) async {
      final id = input.mkey;
      await beforeDelete(input);
      final response = await repository.delete(repository.keyToId(id));
      await afterDelete(id);
      _data.remove(input.mkey);
      return response.deleted;
    });
  }

  Future clear() async {
    final nextLoad = _reloadCompletions.stream.first;
    if (!_values.isFirstResolved) {
      await nextLoad;
    }
    if (_data.isNotEmpty) {
      await _lock.synchronized(() async {
        await applyChanges((changes) {
          _data.keys.forEach((MKey key) => changes.unset(key));
          _data.clear();
        }, replacement: {});
        _values.reset();
      });
    }
  }

  @protected
  void resetCompleteFlag() {
    _values.reset();
  }

  Future<V> saveWith(MKey key, FutureOr modification(V input)) async {
    final record = get(key) as ObservableRecord<V>;
    final existing = await record.future;
    final cloned = repository.clone(existing);
    await modification(cloned);
    await beforeSave(cloned);

    V result;
    bool updated = true;
    if (cloned.mkey?.mxid == null) {
      result = await repository.create(cloned);
      updated = false;
    } else {
      await repository.update(repository.keyToId(key), cloned);
      result = await repository.load(repository.keyToId(key));
//      result = cloned;
    }

    if (updated) await afterUpdate(result);
    if (!updated) await afterCreate(result);
    await afterSave(result);
    applyChanges((_) {
      record.update(result, force: true);
      _.change(key, record);
    });

    return result;
  }

  Future saveAll(
      Iterable<MKey> keys, FutureOr modification(MKey key, V input)) async {
    final debugId = "saveAll[${uuid().truncate(6)}] ";
    log.info("$debugId Starting batch update with ${keys.length} keys");
    await applyChanges((_) async {
      await keys.toStream().mapAsyncLimited((key) async {
        final record = this.get(key) as ObservableRecord<V>;
        final existing = await record.future;
        final cloned = repository.clone(existing);
        await modification(key, cloned);
        await beforeSave(cloned);

        V result;
        bool updated = true;
        if (cloned.mkey?.mxid == null) {
          result = await repository.create(cloned);
          updated = false;
        } else {
          await repository.update(repository.keyToId(key), cloned);
          result = cloned;
        }

        if (updated) await afterUpdate(result);
        if (!updated) await afterCreate(result);
        await afterSave(result);
        await record.update(result, force: true);
        _.change(key, record);
        log.info("$debugId Processed $key");
      }, maxPending: 4).drain();
      log.info("$debugId Finishing");
    });
  }

  @protected
  FutureOr beforeSave(V toSave) {}

  /// Runs only on update
  @protected
  FutureOr afterUpdate(V saved) {}

  /// Runs after update or creation
  @protected
  FutureOr afterSave(V saved) {}

  /// Runs only after creation
  @protected
  FutureOr afterCreate(V saved) {}

  @protected
  FutureOr beforeDelete(V toDelete) {}

  @protected
  FutureOr afterDelete(MKey id) {}

  Future<V> reload(MKey id) async {
    final record = _internalGet(id);
    record.load(repository.load(repository.keyToId(id)));
    return await record.future;
  }

  void takeFrom(V _source, V _target) {
    repository.takeFrom(_source, _target);
  }

  @protected
  ObservableRecord<V> _internalGet(MKey id, [V value]) => runInAction(() {
        if (!_data.containsKey(id)) {
          log.fine("Creating ${id.mxid}");
        } else {
          log.fine("Found existing ${id.mxid}");
        }
        return _data.putIfAbsent(id, () => _createRecord(id, value));
      });

  ObservableRecord<V> _createRecord(MKey id, [V value]) {
    final record = value != null
        ? Record<V>.ofValue(id, value, repository.initialize)
        : Record<V>.idOnly(id);
    return record as ObservableRecord<V>;
  }

  final StreamController<MapDiffs<MKey, Record<V>>> _diffStreamController;

  ValueStream<Map<MKey, Record<V>>> get entryStream => ValueStream.of(_data,
      _diffStreamController.stream.map((changes) => changes.replacement));
}
