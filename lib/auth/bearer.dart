import 'dart:async';
import '../query_param.dart';
import 'authentication.dart';

class BearerAuthentication implements Authentication {
  final String accessToken;

  const BearerAuthentication(this.accessToken);
  @override
  FutureOr applyToParams(
      QueryParams queryParams, Map<String, String?> headerParams) {
    headerParams["Authorization"] = "Bearer $accessToken";
  }

  @override
  get lastAuthentication => accessToken;
}
