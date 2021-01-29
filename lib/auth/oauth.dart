import '../query_param.dart';
import 'authentication.dart';

class OAuth implements Authentication {
  String accessToken;

  OAuth({this.accessToken});

  @override
  void applyToParams(QueryParams params, Map<String, String> headerParams) {
    if (accessToken != null) {
      headerParams["Authorization"] = "Bearer " + accessToken;
    }
  }

  void setAccessToken(String accessToken) {
    this.accessToken = accessToken;
  }

  @override
  get lastAuthentication => accessToken;
}
