import 'm_model.dart';

abstract class MBaseModel {

  Map<String, dynamic> toMap();

  dynamic operator [](key);

  void operator []=(String key, value);

  MSchemaRef get mtype;
}

mixin MBaseModelMixin implements MBaseModel {
  @override
  String toString() => toMap().toString();

  @override
  MKey? get mkey {
    return id == null ? null : MKey.fromType(mtype, id!);
  }

}
