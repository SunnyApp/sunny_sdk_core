import 'dart:async';
import 'dart:convert' as encode;

import 'package:dartxx/dartxx.dart';
import 'package:flutter/foundation.dart';
import 'package:pfile/pfile_api.dart';
import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/query_param.dart';

class ApiResponse {
  final int statusCode;
  final String body;

  const ApiResponse(this.statusCode, this.body);

  get json {
    return encode.jsonDecode(body);
  }
}

class ApiStreamResponse {
  final int statusCode;
  final Stream<List<int>> stream;

  const ApiStreamResponse(this.statusCode, this.stream);

  Future<ApiResponse> toApiResponse() async {
    var streamList = (await stream.toList());
    return ApiResponse(
      statusCode,
      String.fromCharCodes(streamList.flatten()),
    );
  }
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
      {String? basePath}) async {
    var resp = await streamAPI(path, method, queryParams, files, body,
        headerParams, formParams, contentType,
        basePath: basePath);
    return resp.toApiResponse();
  }

  Future<ApiStreamResponse> streamAPI(
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
      serialized = encode.json.encode(obj);
    }
    return serialized;
  }
}

extension ApiResponseJsonExt on ApiResponse {}

Map<String, Object?> _mapOf(data) {
  return data is Map ? data.cast<String, Object?>() : {};
}
