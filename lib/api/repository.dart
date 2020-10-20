import 'dart:async';

import 'package:meta_forms/mverse.dart';
import 'package:sunny_dart/helpers/functions.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_sdk_core/api/api_registry.dart';
import 'package:sunny_sdk_core/model/change_result.dart';
import 'package:sunny_sdk_core/model/delete_response.dart';

typedef PersistenceLifecycleEvent<T> = dynamic Function(T input);

/// Base interface for defining persistence endpoints.  Can be plugged into [SunnyStore] for convenient API access
abstract class Repository<V extends Entity> {
  /// A reference back to the api registry
  ApiRegistry get apis => null;

  V instantiate([dynamic json]) => illegalState("Not implemented");

  Future<ChangeResult> update(String id, V body) =>
      illegalState("Not implemented");

  Future<MModelList<V>> list({double limit, double offset}) =>
      illegalState("Not implemented");

  Future<V> create(V body) => illegalState("Not implemented");

  Future<DeleteResponse> delete(String id) => illegalState("Not implemented");

  Future<V> load(String id) => illegalState("Not implemented");

  V initialize(V entity) => entity;

  /// Copies values from one entity into another.  This clone operation is important because it allows
  // us to actually track differences.  The big caveat is that the clone method should ensure that any
  // subscribable objects are transferred.
  V clone(V source) => illegalState("Not implemented");

  /// Copies all data from [source] into [target].  Used when you want to maintain a reference to [target],
  /// but want to inject new values from [source]
  void takeFrom(V source, V target) => illegalState("Not implemented");

  String keyToId(MKey key);
  MSchemaRef get mtype;
}

/// This mixin is applied to auto-generated apis, and ensures that the modification events are propagated and can be
/// listened to.
mixin SignalingApiMixin<V extends Entity> on Repository<V> {
  @override
  Future<V> create(V body) => super
      .create(body)
      .also((result) => apis.afterCreate(result.mkey, result))
      .futureValue();

  @override
  Future<DeleteResponse> delete(String id) => super
      .delete(id)
      .also((result) => apis.afterDelete<V>(mtype.mkey(id), result))
      .futureValue();

  @override
  Future<ChangeResult> update(String id, V body) => super
      .update(id, body)
      .also((result) => apis.afterUpdate<V>(mtype.mkey(result), body, result))
      .futureValue();
}

//mixin MappingRepositoryMixin<V extends Keyed> on Repository<V> {
//  Repository<T> map<T extends Keyed>({T to(V from), V from(T from)}) {
//    return MappingRepository(this, to: to, from: from);
//  }
//}

//mixin RepositoryApi<V> {}

//typedef Mapper<F, T> = T Function(F from);

///// A repository that can convert to an from an intermediate model
//class MappingRepository<F extends Keyed, T extends Keyed> with Repository<T> {
//  final Repository<F> sourceRepository;
//  final Mapper<F, T> to;
//  final Mapper<T, F> from;
//  final Mapper<T, T> cloner;
//  final Consumer<T> afterSave;
//
//  MappingRepository(
//    this.sourceRepository, {
//    @required this.to,
//    @required this.from,
//    Mapper<T, T> cloner,
//    this.afterSave,
//  }) : cloner = cloner ?? ((_in) => to(sourceRepository.clone(from(_in))));
//
//  T _afterSave(T saved) {
//    afterSave?.call(saved);
//    return saved;
//  }
//
//  @override
//  Future<T> create(T input) async {
//    final result = await sourceRepository.create(from(input));
//    return _afterSave(to(result));
//  }
//
//  @override
//  Future delete(T toDelete) {
//    return sourceRepository.delete(from(toDelete));
//  }
//
//  @override
//  T instantiate([json]) {
//    return to(sourceRepository.instantiate(json));
//  }
//
//  @override
//  Future<T> load(String key) async {
//    return to(await sourceRepository.load(key));
//  }
//
//  @override
//  Future<List<T>> list({int offset, int limit}) async {
//    final result = await sourceRepository.list(offset: offset, limit: limit);
//    return result.map(to).toList();
//  }
//
//  @override
//  Future<ChangeResult> save(T input) async {
//    final changes = await sourceRepository.save(from(input));
//    return changes;
//  }
//
//  @override
//  T clone(T source) {
//    return to(sourceRepository.clone(from(source)));
//  }
//
//  void takeFrom(T source, T target) {
//    sourceRepository.takeFrom(from(source), from(target));
//  }
//}
