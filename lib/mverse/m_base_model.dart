import 'm_model.dart';

abstract class MBaseModel {
  Map<String, dynamic> toMap();

  dynamic operator [](key);

  void operator []=(String key, value);

  /// Used for meta-forms in setting deep properties
  void takeFromMap(Map<String, dynamic> map, {bool copyEntries = true});

  MSchemaRef get mtype;
}

mixin MBaseModelMixin implements MBaseModel {
  @override
  String toString() => toMap().toString();
}
