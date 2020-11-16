// import 'dart:async';
//
// import 'package:collection_diff/diff_equality.dart';
// import 'package:flutter/widgets.dart' hide Listener;
// import 'package:mobx/mobx.dart' hide ObservableMap;
// import 'package:observable_collections/observable_collections.dart';
// import 'package:stream_transform/stream_transform.dart';
// import 'package:sunny_dart/sunny_dart.dart';
// import 'package:sunny_dart/typedefs.dart';
//
// import '../failures.dart';
// import 'm_model.dart';
//
// typedef RecordMutation<T> = T Function(T);
//
// /// A class that wraps an entity, and allows us to work with it before and during it's loading lifecycle.
// abstract class Record<T extends Entity> with DiffDelegateMixin {
//   /// Creates a record without a key (a new record, for example)
//   factory Record.noKey(T value, [T initialize(T value)]) =>
//       ObservableRecord._(null, value, null, initialize);
//
//   /// Creates a new record based on a future
//   factory Record.ofFuture(MKey mkey, Future<T> value,
//           [T initialize(T value)]) =>
//       ObservableRecord._(mkey, null, value, initialize);
//
//   /// Creates a record based off a resolved value
//   factory Record.ofValue(MKey mkey, T value, [T initialize(T value)]) =>
//       ObservableRecord._(mkey, value, null, initialize);
//
//   /// Creates a record with only an ID
//   factory Record.idOnly(MKey mkey) => ObservableRecord._(mkey, null, null);
//
//   MKey get mkey;
//
//   String get id;
//
//   T get value;
//
//   T get valueOrNull;
//
//   FutureOr<T> get futureOr;
//
//   bool get isFuture;
//
//   bool get isResolved;
//
//   bool get isNotLoaded;
//
//   Future<T> get future;
//
//   Stream<T> get recordStream;
//
//   Record<T> clone();
//
//   Dispose observe(
//     Listener<ChangeNotification<TrackedValue<T>>> listener, {
//     bool fireImmediately,
//   });
//
//   static Predicate<Record<T>> isRecordResolved<T extends Entity>() =>
//       (e) => e.isResolved;
//
//   static Mapping<Record<T>, String> toId<T extends Entity>() =>
//       (resolved) => resolved.id;
//
//   static Record<T> keyed<T extends Entity>(T value) {
//     return Record.ofValue(value.mkey, value);
//   }
//
//   void update(T value, {bool force = true, bool silent = false});
// }
//
// class ObservableRecord<T extends Entity>
//     with LoggingMixin, DiffDelegateMixin
//     implements Record<T> {
//   /// The underlying observable.  Using the TrackedValue wrapper because it allows us to force updates
//   final Observable<TrackedValue<T>> _observed;
//   final MKey mkey;
//   dynamic _error;
//
//   int pending = 0;
//   int count = 0;
//
//   /// Tracks update requests and debounces them
//   final StreamController<Producer<T>> _updateRequests = StreamController();
//
//   final StreamController<T> _stream;
//
//   @override
//   String get loggerName {
//     return "record.${T.simpleName}.${mkey?.mxid ?? "no-mxid"}";
//   }
//
//   ObservableRecord._(MKey mkey, T value, Future<T> future,
//       [T initialize(T value)])
//       : this.__(
//           mkey,
//           Observable(
//             TrackedValue(initialize == null ? value : initialize(value)),
//           ),
//           value,
//           future,
//           initialize,
//         );
//
//   ObservableRecord.__(this.mkey, this._observed, T value, Future<T> future,
//       [T initialize(T value)])
//       : _stream = StreamController.broadcast() {
//     _updateRequests.stream.asyncMapBuffer((updates) {
//       Completer completer = Completer();
//       complete(T v) {
//         if (initialize != null) {
//           v = initialize(v);
//         }
//         if (!completer.isCompleted) {
//           this._update(v);
//           completer.complete(v);
//         }
//         pending -= updates.length;
//       }
//
//       for (final fn in updates) {
//         FutureOr<T> v = fn();
//         if (v is T) {
//           complete(v);
//         } else if (v is Future<T>) {
//           v.then((resolved) {
//             complete(resolved);
//           });
//         }
//       }
//
//       return completer.future;
//     }).listen((_) {}, cancelOnError: false);
//
//     if (future != null) {
//       _scheduleUpdate(() => future);
//     } else if (value != null) {
//       _scheduleUpdate(() => value);
//     }
//   }
//
//   String get id => mkey?.toString();
//
//   void _scheduleUpdate(Producer<T> future) {
//     pending++;
//     _updateRequests.add(future);
//   }
//
//   /// Retrieves the underlying value
//   T get value {
//     if (_error != null) throw _error;
//     return isResolved
//         ? _observed.value.tracked
//         : nullPointer(
//             "Entity $T[id=$id] hasn't been initialized: ${_observed.value.tracked}");
//   }
//
//   /// Retrieves the underlying value
//   T get valueOrNull {
//     if (_error != null) throw _error;
//     return _observed.value.tracked;
//   }
//
//   /// Retrieves the values as a [FutureOr<V>]
//   FutureOr<T> get futureOr =>
//       (isResolved ? value : _stream.stream.first as FutureOr<T>);
//
//   /// Watches
//   Dispose observe(
//     Listener<ChangeNotification<TrackedValue<T>>> listener, {
//     bool fireImmediately,
//   }) =>
//       _observed.observe(listener, fireImmediately: fireImmediately);
//
//   @override
//   ObservableRecord<T> clone() {
//     return ObservableRecord._(mkey, value?.clone() as T, _stream.stream.first);
//   }
//
//   @override
//   void takeFrom(dynamic source) {
//     final T value = this.value?.clone() as T;
//     if (value != null) {
//       value.takeFrom(source);
//       this.update(value, force: true);
//     }
//   }
//
//   @override
//   Stream<T> get recordStream {
//     return _stream.stream;
//   }
//
//   void update(T value, {bool force = true, bool silent = false}) {
//     _scheduleUpdate(() => value);
//   }
//
//   _update(T value, {bool force = true, bool silent = false}) {
//     assert(!(value == null && valueOrNull != null),
//         "Why are we removing a perfectly good value??");
//     runInAction(() {
//       if (silent != true) {
//         _internalUpdate(value, force: force);
//       } else {
//         untracked(() {
//           _internalUpdate(value, force: false);
//         });
//       }
//     });
//   }
//
//   _internalUpdate(T value, {bool force = false}) {
//     count++;
//     log.fine("Pushing updated value to stream: $count (force=$force)");
//     _stream?.add(value);
//     _observed.value = _observed.value.updated(value, force: force);
//     _error = null;
//   }
//
//   load(Future<T> future, [T initializer(T input)]) async {
//     _scheduleUpdate(() async {
//       T resolved = await future;
//       if (initializer != null) {
//         resolved = initializer(resolved);
//       }
//       return resolved;
//     });
//   }
//
//   FutureOr<T> modify(T modification(T input),
//       {@required bool ignoreNotLoaded}) {
//     if (modification == null) return value;
//     // ericm this was causing issues with assisted tasks - the pack tasks weren't loaded yet
//     assert(!isNotLoaded || ignoreNotLoaded == true, "Should be loaded");
//     if (isFuture) {
//       return future.then((value) {
//         update(modification(value));
//         return value;
//       });
//     } else {
//       update(modification(value));
//       return value;
//     }
//   }
//
//   bool get isFuture => pending > 0;
//
//   bool get isResolved => _observed.value.tracked != null;
//
//   bool get isNotLoaded => valueOrNull == null && !isFuture;
//
//   Future<T> get future {
//     if (_error != null) return Future.error(_error);
//     final _resolved = !isResolved;
//     return _resolved ? _stream.stream.first : Future.value(this.value);
//   }
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is Record &&
//           runtimeType == other.runtimeType &&
//           id == other.id &&
//           T == T &&
//           (isResolved && other.isResolved && value == other.value);
//
//   @override
//   int get hashCode => id.hashCode;
//
//   @override
//   dynamic get diffSource {
//     final _value = this.valueOrNull;
//     if (_value == null) {
//       return {"id": id, "type": T.toString()};
//     } else {
//       return null;
//     }
//   }
//
// //  @override
// //  ValueStream<T> get stream {
// //    final controller = ValueStream.controller<T>(initialValue: valueOrNull);
// //    observe((notification) {
// //      controller.add(notification.newValue.tracked);
// //    });
// //    return controller.stream;
// //  }
//
//   @override
//   String get diffKey => id;
// }
