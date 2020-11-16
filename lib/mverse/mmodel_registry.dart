import 'package:sunny_dart/sunny_dart.dart';

import 'm_model.dart';

/// Contains all registered [MModel] types to support deserialization.  The registry reads the mtype property in
/// the json object, and finds the appropriate factory method.
class MModelRegistry with LoggingMixin {
  final Map<String, MModelFactory> _factories = {};

  void register(MSchemaRef type, MModelFactory factory) {
    if (type.value?.isNotEmpty != true) {
      return;
    }
    if (_factories.containsKey("$type")) {
      log.info("WARN:  Factory already registered for $type");
    }

    _factories["$type"] = assertNotNull(factory);
  }

  operator [](String mtype) => _factories[mtype];

  M instantiate<M extends MModel>({dynamic json, MSchemaRef type}) {
    final Map<String, dynamic> map =
        (json as Map<String, dynamic>) ?? <String, dynamic>{};
    var mtype = map["mtype"];
    if (mtype == null) {
      final mmeta = map["mmeta"];
      if (mmeta != null) {
        mtype = mmeta["mtype"];
      }
    }

    mtype ??= "$type";
    if (mtype == null) {
      nullPointer(
          "No mmodel type could be extracted from json payload.  Set either the mtype or mmeta/mtype properties");
    }

    final MModelFactory<M> factory = _factories[mtype] as MModelFactory<M>;
    if (map.isEmpty && factory == null) return null;
    if (factory == null && map.isNotEmpty) {
      if (M == MEntity || M == MModel) {
        log.severe(
            "No mmodel type could be extracted from json payload.  Set either the mtype or mmeta/mtype properties");
        return DefaultMEntity(map) as M;
      } else {
        throw Exception(
            "No mmodel type could be extracted from json payload.  Set either the mtype or mmeta/mtype properties");
      }
    }
    return factory(map);
  }

  MModelRegistry._();
}

class DefaultMEntity extends MEntity {
  DefaultMEntity(Map<String, dynamic> wrapped) : super(wrapped);

  @override
  String get id => illegalState("Not implemented");

  void takeFrom(source) => illegalState("Not implemented");
}

MModelRegistry get mmodelRegistry => _mmodelRegistry ??= MModelRegistry._();
MModelRegistry _mmodelRegistry;

initializeMModelRegistry(MModelRegistry registry) {
  _mmodelRegistry = registry;
}

typedef MModelFactory<M extends MModel> = M Function(dynamic json);
