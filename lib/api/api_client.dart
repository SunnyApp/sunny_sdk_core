import 'dart:convert';
import 'dart:async';
import 'package:sunny_dart/extensions.dart';
import 'package:meta/meta.dart';
import 'package:pfile/pfile.dart';
import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_dart/helpers/tuple.dart';
import 'package:sunny_sdk_core/api/api_client_transport.dart';
import 'package:sunny_sdk_core/auth/api_key_auth.dart';
import 'package:sunny_sdk_core/auth/authentication.dart';
import 'package:sunny_sdk_core/query_param.dart';
import 'package:sunny_sdk_core/request_builder.dart';

import 'api_exceptions.dart';
import 'api_reader.dart';

class ApiClient with LoggingMixin {
  static const kBearer = "Bearer";

  final ApiClientTransport transport;

  String basePath;
  Map<String, String> basePaths;
  final ApiReader serializer;
  final String defaultAuthName;
  final Map<String, dynamic> defaultHeaderMap = {};
  final Map<String, Authentication> authentications = {};

  ApiClient({@required this.transport,
    this.basePath = "https://localhost:8080",
    this.defaultAuthName = kBearer,
    this.serializer,
    Map<String, String> basePaths,
    Authentication authentication})
      : basePaths = basePaths ?? {} {
    // Setup authentications (key: authentication name, value: authentication).
    authentications['Bearer'] =
        authentication ?? ApiKeyAuth("header", "Authorization");
  }

  String get currentAccessToken {
    final bearer = authentications.values.first;
    if (bearer is ApiKeyAuth) {
      return bearer.apiKey;
    } else {
      return bearer?.lastAuthentication?.toString();
    }
  }

  Future<Tuple<QueryParams, Map<String, String>>> applyAuthHeader(
      {QueryParams queryParams, Map<String, String> headers}) async {
    queryParams ??= QueryParams();
    headers ??= {};
    for (var auth in authentications.values) {
      await auth.applyToParams(queryParams, headers);
    }
    return Tuple(queryParams, headers);
  }

  void addDefaultHeader(String key, String value) {
    defaultHeaderMap[key] = value;
  }

  dynamic _deserialize(dynamic value, String targetType) {
    try {
      final deser = this.serializer.getReader(value, targetType);
      if (deser == null) {
        throw ApiException.response(500,
            'Could not find a suitable class for deserialization of $targetType');
      }
      return deser(value);
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      log.severe("Error decoding response: $e", e, stack);
      throw ApiException.runtimeError(e, stack);
    }
  }

  dynamic deserialize(String jsonVal, String targetType) {
    // Remove all spaces.  Necessary for reg expressions as well.
    targetType = targetType.replaceAll(' ', '');
    if (targetType == 'String') return jsonVal;

    var decodedJson = json.decode(jsonVal);
    return _deserialize(decodedJson, targetType);
  }

  /// Update query and header parameters based on authentication settings.
  /// @param authNames The authentications to apply
  Future updateParamsForAuth(Set<String> authNames, QueryParams queryParams,
      Map<String, String> headerParams) async {
    for (var authName in authNames.orEmpty()) {
      Authentication auth = authentications[authName];
      if (auth == null) {
        throw ArgumentError("Authentication undefined: " +
            authName +
            " but found ${authentications.keys}");
      }
      await auth.applyToParams(queryParams, headerParams);
    }
  }

  T decodeAs<T>(String jsonVal) {
    if (T == String) {
      return jsonVal as T;
    }

    // Remove all spaces.  Ne|cessary for reg expressions as well.
    final targetType = "$T".replaceAll(' ', '');

    var decodedJson = json.decode(jsonVal);
    return _deserialize(decodedJson, targetType) as T;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi' a key might appear multiple times.
  Future<ApiResponse> invokeRequest(RequestBuilder request) async {
    final authNames = request.authNames ??
        [
          if (defaultAuthName != null) defaultAuthName,
        ];

    await updateParamsForAuth(
        authNames?.toSet(), request.queryParams, request.headerParams);

    return transport.invokeAPI(
        request.requestRelativeUrl,
        request.method.enumValue,
        request.queryParams,
        request.files,
        request.body,
        request.headerParams,
        request.formParams,
        request.contentType,
        basePath: request.basePath);
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi' a key might appear multiple times.
  Future<ApiResponse> invoke(String path,
      String method,
      QueryParams queryParams,
      Iterable<PFile> files,
      Object body,
      Map<String, String> headerParams,
      Map<String, String> formParams,
      String contentType,
      List<String> authNames, {String basePath}) async {
    authNames ??= [
      if (defaultAuthName != null) defaultAuthName,
    ];

    await updateParamsForAuth(authNames.toSet(), queryParams, headerParams);

    return transport.invokeAPI(
        path,
        method,
        queryParams,
        files,
        body,
        headerParams,
        formParams,
        contentType,
        basePath: basePath);
  }
}
