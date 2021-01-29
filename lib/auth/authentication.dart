import 'dart:async';

import 'package:sunny_sdk_core/query_param.dart';

abstract class Authentication {
  /// Apply authentication settings to header and query params.
  FutureOr applyToParams(
      QueryParams queryParams, Map<String, String> headerParams);

  dynamic get lastAuthentication => null;
}
