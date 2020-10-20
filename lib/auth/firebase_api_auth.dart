import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/api/api_exceptions.dart';
import 'package:sunny_sdk_core/sunny_sdk_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Special subclass that consults the firebase global and attaches the token
/// to the request
class FirebaseApiAuth extends Authentication with LoggingMixin {
  FirebaseApiAuth._();
  factory FirebaseApiAuth() => _instance;
  static fb.User user;
  static final _instance = FirebaseApiAuth._();
  String lastApiKey;

  @override
  Future applyToParams(
      List<QueryParam> queryParams, Map<String, String> headerParams) async {
    try {
      if (user != null) {
        final token = await user.getIdToken();
        lastApiKey = token;
        headerParams["Authorization"] = "Bearer $token";
      } else {
        log.info("No firebase user for request");
      }
    } on fb.FirebaseAuthException {
      throw ApiException.response(401, "Not authenticated");
    } catch (e, stack) {
      throw ApiException.runtimeError(e, stack);
    }
  }
}
