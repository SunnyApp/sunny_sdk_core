import 'package:sunny_dart/helpers/functions.dart';
import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/api_exports.dart';
import 'package:sunny_sdk_core/mverse/mmodel_registry_type_extractors.dart';

import 'm_model.dart';

/// Contains all registered [MBaseModel] types to support deserialization.  The registry reads the mtype property in
/// the json object, and finds the appropriate factory method.
class MModelRegistry with LoggingMixin {
  final Map<String, MModelFactory> _factories = {};
  final List<TypeExtractor> _typeExtractors = [extractMverseType];

  void registerTypeExtractor(TypeExtractor typeExtractor) {
    if (!_typeExtractors.contains(typeExtractor)) {
      _typeExtractors.add(typeExtractor);
    }
  }

  void clearTypeExtractors() {
    _typeExtractors.clear();
  }

  void register(MSchemaRef type, MModelFactory factory) {
    if (type.value.isNotEmpty != true) {
      return;
    }
    if (_factories.containsKey("$type")) {
      log.info("WARN:  Factory already registered for $type");
    }

    _factories["$type"] = assertNotNull(factory);
  }

  operator [](String mtype) => _factories[mtype];

  M instantiate<M extends MBaseModel>({dynamic json, MSchemaRef? type}) {
    final Map<String, dynamic> map = (json as Map<String, dynamic>?) ?? <String, dynamic>{};
    final mtype = _typeExtractors.map((extract) => extract(map, fallbackType: type)).firstWhere((element) => element != null,
        orElse: () =>
            nullPointer("No mmodel type could be extracted from json payload.  Set either the mtype or mmeta/mtype properties"));

    final MModelFactory<M>? factory = _factories[mtype] as MModelFactory<M>?;
    if (map.isEmpty && factory == null) {}
    if (factory == null && map.isNotEmpty) {
      if (M == MEntity || M == MModel || M == MBaseModel) {
        log.severe("No mmodel type could be extracted from json payload.  Set either the mtype or mmeta/mtype properties");
        return DefaultMEntity(map) as M;
      } else {
        throw Exception("No mmodel type could be extracted from json payload.  Set either the mtype or mmeta/mtype properties");
      }
    }
    if (factory == null) {
      throw Exception("No factory was provided for type ${mtype}. "
          "Make sure you call register[Library]Models(mmodelRegistry, mEnumRegistry). ");
    } else {
      return factory(map);
    }
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
MModelRegistry? _mmodelRegistry;

initializeMModelRegistry(MModelRegistry registry) {
  _mmodelRegistry = registry;
}

typedef MModelFactory<M extends MBaseModel> = M Function(dynamic json);

/// Attempts to determine the entity type
typedef TypeExtractor = String? Function(Map<String, dynamic> json, {MSchemaRef? fallbackType});
