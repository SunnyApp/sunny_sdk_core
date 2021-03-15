import 'dart:async';
import 'dart:convert';

import 'package:pfile/pfile_api.dart';
import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/query_param.dart';

class ApiResponse {
  final int statusCode;
  final String body;

  ApiResponse(this.statusCode, this.body);
}

abstract class ApiClientTransport with LoggingMixin {
  String get basePath;
  // String get defaultAuthName;
  // final Map<String, Authentication> authentications = {};
  // final Map<String, dynamic> defaultHeaderMap = {};

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi' a key might appear multiple times.
  Future<ApiResponse> invokeAPI(
      String path,
      String? method,
      QueryParams queryParams,
      Iterable<PFile> files,
      Object? body,
      Map<String, String?> headerParams,
      Map<String, String> formParams,
      String? contentType,
      {String? basePath});

  String serialize(Object? obj) {
    String serialized = '';
    if (obj == null) {
      serialized = '';
    } else {
      serialized = json.encode(obj);
    }
    return serialized;
  }
}
