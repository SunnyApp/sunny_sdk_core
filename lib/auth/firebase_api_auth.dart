import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/api/api_exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:sunny_sdk_core/auth/authentication.dart';
import 'package:sunny_sdk_core/query_param.dart';

/// Special subclass that consults the firebase global and attaches the token
/// to the request
class FirebaseApiAuth with LoggingMixin implements Authentication {
  FirebaseApiAuth._();
  factory FirebaseApiAuth() => _instance;
  static fb.User user;
  static final _instance = FirebaseApiAuth._();
  String lastApiKey;

  @override
  Future applyToParams(
      QueryParams queryParams, Map<String, String> headerParams) async {
    try {
      if (user != null) {
        final token = await user.getIdToken();
        lastApiKey = token;
        headerParams["Authorization"] = "Bearer $token";
      } else {
        log.fine("No firebase user for request");
      }
    } on fb.FirebaseAuthException {
      throw ApiException.response(401, "Not authenticated");
    } catch (e, stack) {
      throw ApiException.runtimeError(e, stack);
    }
  }

  @override
  get lastAuthentication => lastApiKey;
}
