import 'package:sunny_sdk_core/api/api_client_transport.dart';
import 'package:sunny_sdk_core/api_exports.dart';

import '../api.dart';
import '../auth.dart';

/// A portable object for passing api configuration across isolates.
class ApiConfig {
  final String basePath;
  final Map<String, String> basePaths;
  final Map<String, dynamic> options;
  final String accessToken;

  ApiConfig(this.basePath, this.basePaths, this.options, this.accessToken)
      : assert(accessToken != null);

  factory ApiConfig.fromClient(ApiClient apiClient) {
    return ApiConfig(apiClient.basePath, apiClient.basePaths, {},
        apiClient.currentAccessToken);
  }

  /// Recreates an authentication state (usually done inside an isolate)
  ApiClient apiClient(
      {@required ApiClientTransport apiClient,
      @required ApiReader reader,
      bool logToFirebase = false}) {
    return ApiClient(
      transport: apiClient,
      basePaths: basePaths,
      serializer: reader,
      authentication: ApiKeyAuth('header', 'Authorization')
        ..apiKey = accessToken,
    );
  }
}
