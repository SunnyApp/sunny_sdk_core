import 'package:sunny_sdk_core/model_exports.dart';

typedef Deserializer = dynamic Function(dynamic input);

abstract class ApiReader {
  Deserializer getReader(final input, String targetType);

  const factory ApiReader.mmodel() = MModelRegistryReader;
}

class PrimitiveApiReader implements ApiReader {
  const PrimitiveApiReader._();
  factory PrimitiveApiReader() {
    return _instance;
  }

  static const _instance = PrimitiveApiReader._();

  Deserializer getReader(final input, String targetType) {
    switch (targetType) {
      case 'String':
        return (value) => '$value';
      case 'int':
        return (value) => value is int ? value : int.parse('$value');
      case 'bool':
        return (value) =>
            value is bool ? value : '$value'.toLowerCase() == 'true';
      case 'double':
        return (value) => value is double ? value : double.parse('$value');
      default:
        return null;
    }
  }
}

abstract class CollectionAwareApiReader with CachingApiReaderMixin {
  static final _listRegEx = RegExp(r'^List<(.*)>$');
  static final _mapRegEx = RegExp(r'^Map<String,(.*)>$');

  /// Finds a deserializer for a single non-collection entity.
  Deserializer findSingleReader(final input, String targetType);

  @override
  Deserializer findReader(final input, String targetType) {
    Match match;
    if (input is List && (match = _listRegEx.firstMatch(targetType)) != null) {
      return (v) {
        final value = v as List;
        var newTargetType = match[1];
        return value.map((v) => findSingleReader(v, newTargetType)(v)).toList();
      };
    } else if (input is Map &&
        (match = _mapRegEx.firstMatch(targetType)) != null) {
      return (v) {
        final value = v as Map;
        var newTargetType = match[1];
        return Map.fromIterables(
            value.keys,
            value.values
                .map((v) => (v) => findSingleReader(v, newTargetType)(v)));
      };
    } else {
      return findSingleReader(input, targetType);
    }
  }
}

mixin CachingApiReaderMixin implements ApiReader {
  final Map<String, Deserializer> _cached = {};

  @mustCallSuper
  @override
  Deserializer getReader(final input, String targetType) {
    return getOrCacheReader(input, targetType);
  }

  Deserializer getOrCacheReader(final input, String targetType) {
    return _cached.putIfAbsent(targetType, () => findReader(input, targetType));
  }

  Deserializer findReader(final input, String targetType);
}

class AggregateApiReader with CachingApiReaderMixin {
  final Iterable<ApiReader> _readers;

  AggregateApiReader([
    ApiReader reader1,
    ApiReader reader2,
    ApiReader reader3,
    ApiReader reader4,
    ApiReader reader5,
  ]) : _readers = [reader1, reader2, reader3, reader4, reader5].whereNotNull();

  Deserializer findReader(input, String targetType) {
    for (final reader in _readers) {
      final _ = reader.getReader(input, targetType);
      if (_ != null) {
        return _;
      }
    }
    return null;
  }
}

const _delimiters = const {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};

extension ApiReaderExt on ApiReader {
  String parameterToString(value) {
    if (value == null) {
      return '';
    } else if (value is DateTime) {
      return value.toUtc().toIso8601String();
    } else {
      return value.toString();
    }
  }

// port from Java version
  Iterable<QueryParam> convertParametersForCollectionFormat(
      String collectionFormat, String name, dynamic value) {
    var params = <QueryParam>[];

    // preconditions
    if (name == null || name.isEmpty || value == null) return params;

    if (value is! List) {
      params.add(QueryParam(name, parameterToString(value)));
      return params;
    }

    List values = value as List;

    // get the collection format
    collectionFormat = (collectionFormat == null || collectionFormat.isEmpty)
        ? "csv"
        : collectionFormat; // default: csv

    if (collectionFormat == "multi") {
      return values.map((v) => QueryParam(name, parameterToString(v)));
    }

    String delimiter = _delimiters[collectionFormat] ?? ",";

    params.add(QueryParam(
        name, values.map((v) => parameterToString(v)).join(delimiter)));
    return params;
  }
}

class MModelRegistryReader implements ApiReader {
  const MModelRegistryReader();

  @override
  Deserializer getReader(input, String targetType) {
    return (value) => mmodelRegistry.instantiate(
        json: value, type: MSchemaRef.fromJson(targetType));
  }
}
