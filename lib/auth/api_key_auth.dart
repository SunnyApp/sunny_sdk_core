import '../query_param.dart';
import 'authentication.dart';

class ApiKeyAuth implements Authentication {
  final String location;
  final String paramName;
  String? apiKey;
  String? apiKeyPrefix;

  ApiKeyAuth(this.location, this.paramName);

  @override
  void applyToParams(QueryParams query, Map<String, String?> headers) {
    String? value;
    if (apiKeyPrefix != null) {
      value = '$apiKeyPrefix $apiKey';
    } else {
      value = apiKey;
    }

    if (location == 'query' && value != null) {
      query[paramName] = value;
    } else if (location == 'header' && value != null) {
      headers[paramName] = value;
    }
  }

  @override
  get lastAuthentication => apiKey;
}
