import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meta_forms/mverse.dart';
import 'package:sunny_sdk_core/store/sunny_store.dart';

typedef AfterDelete = FutureOr Function(MKey id);
typedef BeforeDelete<T> = FutureOr Function(T item);
typedef OnSave<T> = FutureOr Function(T record);
typedef Event<T> = FutureOr Function(T input);

mixin StoreEventsMixin<V extends Entity> on SunnyStore<V> {
  final List<AfterDelete> _afterDeletes = [];
  final List<BeforeDelete<V>> _beforeDeletes = [];
  final List<OnSave<V>> _afterUpdates = [];
  final List<OnSave<V>> _afterSaves = [];
  final List<OnSave<V>> _afterCreates = [];
  final List<OnSave<V>> _beforeSaves = [];

  FutureOr _invokeAll<X>(Iterable<Event<X>> fns, X input) async {
    final results = fns.map((fn) => fn(input)).whereType<Future>();
    if (results.isEmpty == true) {
      return true;
    } else {
      await Future.wait(results.cast<Future>());
      return true;
    }
  }

  @mustCallSuper
  @protected
  FutureOr beforeSave(V toSave) => _invokeAll(_beforeSaves, toSave);

  @mustCallSuper
  @protected
  FutureOr afterUpdate(V saved) => _invokeAll(_afterUpdates, saved);

  @mustCallSuper
  @protected
  FutureOr afterSave(V saved) => _invokeAll(_afterSaves, saved);

  @mustCallSuper
  @protected
  FutureOr afterCreate(V saved) => _invokeAll(_afterCreates, saved);

  @mustCallSuper
  @protected
  FutureOr beforeDelete(V toDelete) => _invokeAll(_beforeDeletes, toDelete);

  @mustCallSuper
  @protected
  FutureOr afterDelete(MKey id) => _invokeAll(_afterDeletes, id);

  registerAfterDelete(AfterDelete afterDelete) =>
      _afterDeletes.add(afterDelete);

  registerBeforeDelete(BeforeDelete<V> handler) => _beforeDeletes.add(handler);

  registerAfterSave(Event<V> handler) => _afterSaves.add(handler);

  registerAfterCreate(Event<V> handler) => _afterCreates.add(handler);
}
