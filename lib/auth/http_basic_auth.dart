import 'package:sunny_sdk_core/auth.dart';

import '../query_param.dart';

class HttpBasicAuthentication extends Authentication {
  @override
  void applyToParams(List<QueryParam> query, Map<String, String> headers) {}
}
