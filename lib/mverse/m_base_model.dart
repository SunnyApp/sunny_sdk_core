import 'm_model.dart';

typedef JsonObject = Map<String, dynamic>;
typedef JsonValue = dynamic;

abstract class MBaseModel implements Entity {
  String? get id;

  JsonObject toMap();

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
