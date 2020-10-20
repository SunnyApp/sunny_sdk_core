import 'package:sunny_sdk_core/model_exports.dart';

typedef Deserializer = dynamic Function(dynamic input);

abstract class ApiReader {
  Deserializer getReader(final input, String targetType);

  String parameterToString(input);
  const factory ApiReader.mmodel() = MModelRegistryReader;
}

const _delimiters = const {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};

extension ApiReaderExt on ApiReader {
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

  @override
  String parameterToString(value) {
    if (value == null) {
      return '';
    } else if (value is DateTime) {
      return value.toUtc().toIso8601String();
    } else {
      return value.toString();
    }
  }
}
