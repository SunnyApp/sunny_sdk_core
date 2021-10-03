import 'm_model.dart';

abstract class MBaseModel implements Entity {
  String? get id;

  Map<String, dynamic> toMap();

  MKey? get mkey;

  dynamic operator [](key);

  void operator []=(String key, value);

  MSchemaRef get mtype;

  dynamic clone();

  void takeFrom(dynamic source);
}

mixin MBaseModelMixin implements MBaseModel {
  @override
  String toString() => toMap().toString();

  @override
  MKey? get mkey {
    return id == null ? null : MKey.fromType(mtype, id!);
  }

  void takeFrom(dynamic source) => throw UnimplementedError();
}
