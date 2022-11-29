import 'package:equatable/equatable.dart';
import 'package:sunny_dart/helpers/logging_mixin.dart';

import 'record_data_service.dart';

class KeyedRelatedData<K, R> with EquatableMixin {
  final K key;
  R related;

  KeyedRelatedData(this.key, this.related);

  @override
  List<Object?> get props => [key, related];
}

typedef RelatedData<R> = KeyedRelatedData<String, R>;

extension NullRelatedData<R> on RelatedData<R>? {
  R? getRelated() => this == null ? null : this!.related;
}

abstract class WrappedRecordDataService<V>
    extends RecordDataService<RelatedData<V>, String> with LoggingMixin {
  @override
  String getIdForRecord(RelatedData<V> record) {
    return record.key;
  }

  @override
  Future<RelatedData<V>> internalFetchRecord(String id) async {
    var related = await internalFetchRelated(id);
    return RelatedData(id, related);
  }

  Future<V> internalFetchRelated(String id);
}
