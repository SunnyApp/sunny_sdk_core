import 'package:sunny_dart/sunny_dart.dart';

typedef MEnumFactory<M> = M Function(String literal);

/// Contains all registered enum types to support deserialization.
class MEnumRegistry with LoggingMixin {
  final Map<String, MEnumFactory> _factories = {};
  final Map<String, List<MLiteral<String>>> _values = {};

  register<T extends MLiteral<String>>(
    String type, {
    required List<T> values,
    required MEnumFactory<T> factory,
  }) {
    if (type.isNotEmpty != true) {
      return;
    }
    if (_factories.containsKey("$type")) {
      log.info("WARN:  Factory already registered for $type");
    }

    _factories["$type"] = assertNotNull(factory);
    _values["$type"] = assertNotNull(values);
  }

  operator [](String mtype) => _factories[mtype];

  List<T> values<T>(String key) {
    return _values[key] as List<T>? ?? <T>[];
  }

  MEnumFactory<T?> factory<T>(String key) {
    return _factories[key] as MEnumFactory<T>? ?? ((String _) => null);
  }

  M instantiate<M extends MLiteral<String>>(dynamic json, {required String type}) {
    final MEnumFactory<M> factory = _factories[type] as MEnumFactory<M>? ?? nullPointer("No enum factory found for $type}");
    return factory(json as String);
  }

  MEnumRegistry._();
}

MEnumRegistry get mEnumRegistry => _mEnumRegistry ??= MEnumRegistry._();
MEnumRegistry? _mEnumRegistry;

initializeMEnumRegistry(MEnumRegistry registry) {
  _mEnumRegistry = registry;
}
