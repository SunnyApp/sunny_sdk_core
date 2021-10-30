import 'package:sunny_sdk_core/path.dart';

import 'm_model.dart';
import 'package:dartxx/json_path.dart';

abstract class MBaseModel {
  Map<String, dynamic> toMap();

  dynamic operator [](key);

  void operator []=(String key, value);

  /// Used for meta-forms in setting deep properties
  void takeFromMap(Map<String, dynamic> map, {bool copyEntries = true});

  T getByPath<T>(JsonPath path);

  dynamic setByPath<T>(JsonPath<T> path, T? value);

  MSchemaRef get mtype;
  Set<String> get mfields;
}

mixin MBaseModelMixin implements MBaseModel {
  @override
  String toString() => toMap().toString();

  T get<T>(String key) {
    return this[key] as T;
  }

  T prop<T>(JsonPath<T> path, [T? value]) {
    if (value != null) {
      setByPath(path, value);
      return value;
    } else {
      return getByPath(path) as T;
    }
  }

  T getByPath<T>(JsonPath path) {
    dynamic value = this;
    for (var segment in path.segments) {
      if (value is MBaseModel) {
        value = value[segment];
      } else if (value is Map) {
        value = value[segment];
      } else {
        throw Exception("Illegal path: $path at segment $segment.  Expected Map or MBaseModel but found ${value.runtimeType}");
      }
      if (value == null) {
        return null as T;
      }
    }
    return value as T;
  }

  void setByPath<T>(JsonPath<T> path, T? value) {
    if (value == "") value = null;
    setDeep(this, path, value);
  }
}
