import 'query_param.dart';

typedef Deserializer = dynamic Function(dynamic input);

abstract class ApiReader {
  Deserializer getReader(final input, String targetType);
  dynamic parameterToString(input);
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
