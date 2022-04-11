import 'package:sunny_dart/helpers/functions.dart';
import 'package:sunny_dart/helpers/lists.dart';
import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/mverse/mmodel_registry_mverse.dart';
export 'mmodel_registry_mverse.dart';
import 'm_base_model.dart';
import 'm_model.dart';

/// Contains all registered [MBaseModel] types to support deserialization.  The registry reads the mtype property in
/// the json object, and finds the appropriate factory method.
class MModelRegistry with LoggingMixin, MModelFactoryRegistry {
  final List<TypeExtractor> _typeExtractors = [extractMverseType];
  final List<MModelFactoryResolver> _resolvers = [];

  void registerTypeExtractor(TypeExtractor typeExtractor) {
    if (!_typeExtractors.contains(typeExtractor)) {
      _typeExtractors.add(typeExtractor);
    }
  }

  void clearTypeExtractors() {
    _typeExtractors.clear();
  }

  void registerFactoryResolver(MModelFactoryResolver resolver) {
    if (!_resolvers.contains(resolver)) {
      _resolvers.add(resolver);
    }
  }

  void clearFactoryResolver() {
    _resolvers.clear();
  }

  MModelFactory? operator [](String mtype) => lookupFactory(mtype);

  MModelFactory? lookupFactory(Object mtype) {
    final key = "$mtype";
    final factory = _resolvers
        .map((resolver) => resolver(key))
        .firstWhere(notNull(), orElse: () {
      return lookupFactory(mtype);
    });
    return factory;
  }

  M instantiate<M extends MBaseModel>({dynamic json, MSchemaRef? type}) {
    final Map<String, dynamic> map =
        (json as Map<String, dynamic>?) ?? <String, dynamic>{};
    final mtype = _typeExtractors.map((extract) => extract(map)).firstWhere(
        notNull(),
        orElse: () =>
            type?.toString() ??
            nullPointer<String>(
                "No mmodel type could be extracted from json payload.  Set either the mtype or mmeta/mtype properties"));

    final factory = lookupFactory(mtype!);
    if (factory == null && map.isNotEmpty) {
      if (M == MEntity || M == MModel || M == MBaseModel) {
        log.severe(
            "No mmodel type could be extracted from json payload.  Set either the mtype or mmeta/mtype properties");
        return DefaultMEntity(map) as M;
      } else {
        throw Exception(
            "No mmodel type could be extracted from json payload. Set either the mtype or mmeta/mtype properties");
      }
    }
    if (factory == null) {
      throw Exception("No factory was provided for type ${mtype}. "
          "Make sure you call register[Library]Models(mmodelRegistry, mEnumRegistry). ");
    } else {
      final generated = factory(map);
      if (generated is! M) {
        throw Exception(
            "Factory was found, but did not generate the correct type");
      }
      return generated;
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

/// Attempts to determine the entity type
typedef TypeExtractor = String? Function(Map<String, dynamic> json);
