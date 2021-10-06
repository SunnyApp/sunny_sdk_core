import 'm_model.dart';

abstract class MBaseModel {
  Map<String, dynamic> toMap();

  dynamic operator [](key);

  void operator []=(String key, value);

  void takeFromMap(Map<String, dynamic> map);

  MSchemaRef get mtype;
}

mixin MBaseModelMixin implements MBaseModel {
  @override
  String toString() => toMap().toString();
}
