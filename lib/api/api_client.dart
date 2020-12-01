import 'dart:convert';

import 'package:http/http.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_sdk_core/auth/authentication.dart';
import 'package:sunny_sdk_core/auth/firebase_api_auth.dart';
import 'package:sunny_sdk_core/query_param.dart';
import 'package:sunny_sdk_core/request_builder.dart';
import 'package:sunny_sdk_core/services/sunny.dart';

import '../auth.dart';
import 'api_exceptions.dart';
import 'api_reader.dart';

ApiClient get apiClient => Sunny.get();

class ApiClient with LoggingMixin {
  static const kBearer = "Bearer";

  String basePath;
  Map<String, String> basePaths;
  final ApiReader serializer;
  final Client client;
  final String defaultAuthName;
  Map<String, String> _defaultHeaderMap = {};
  Map<String, Authentication> _authentications = {};

  ApiClient(
      {this.basePath = "https://localhost:8080",
      Client client,
      this.defaultAuthName,
      this.serializer,
      Map<String, String> basePaths,
      Authentication authentication})
      : basePaths = basePaths ?? {},
        client = client ?? Client() {
    // Setup authentications (key: authentication name, value: authentication).
    _authentications['Bearer'] =
        authentication ?? ApiKeyAuth("header", "Authorization");
  }

  String get currentAccessToken {
    final bearer = _authentications.values.first;
    if (bearer is ApiKeyAuth) {
      return bearer.apiKey;
    } else if (bearer is FirebaseApiAuth) {
      return bearer.lastApiKey;
    } else {
      return null;
    }
  }

  Future applyAuthHeader(
      {List<QueryParam> queryParams, Map<String, String> headers}) async {
    for (var auth in _authentications.values) {
      await auth.applyToParams(queryParams, headers);
    }
  }

  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
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

  T decodeAs<T>(String jsonVal) {
    if (T == String) {
      return jsonVal as T;
    }

    // Remove all spaces.  Ne|cessary for reg expressions as well.
    final targetType = "$T".replaceAll(' ', '');

    var decodedJson = json.decode(jsonVal);
    return _deserialize(decodedJson, targetType) as T;
  }

  String serialize(Object obj) {
    String serialized = '';
    if (obj == null) {
      serialized = '';
    } else {
      serialized = json.encode(obj);
    }
    return serialized;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi' a key might appear multiple times.
  Future<Response> invokeRequest(RequestBuilder request) async {
    return await invokeAPI(
        request.requestRelativeUrl,
        request.method.enumValue,
        request.queryParams.mapEntries((k, v) => QueryParam(k, v?.toString())),
        request.body,
        request.headerParams,
        request.formParams,
        request.contentType,
        request.authNames,
        basePath: request.basePath);
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi' a key might appear multiple times.
  Future<Response> invokeAPI(
      String path,
      String method,
      Iterable<QueryParam> queryParams,
      Object body,
      Map<String, String> headerParams,
      Map<String, String> formParams,
      String contentType,
      Iterable<String> authNames,
      {String basePath}) async {
    basePath ??= this.basePath;
    authNames ??= defaultAuthName.asList();
    await _updateParamsForAuth(
        authNames?.toSet(), [...?queryParams], headerParams);

    var ps = queryParams
        .where((p) => p.value != null)
        .map((p) => '${p.name}=${p.value}');
    String queryString = ps.isNotEmpty ? '?' + ps.join('&') : '';

    String url = basePath + path + queryString;

    headerParams.addAll(_defaultHeaderMap);
    headerParams['Content-Type'] = contentType;
    Response response;
    if (body is MultipartRequest) {
      var request = MultipartRequest(method, Uri.parse(url));
      request.fields.addAll(body.fields);
      request.files.addAll(body.files);
      request.headers.addAll(body.headers);
      request.headers.addAll(headerParams);
      var streamedResp = await client.send(request);
      response = await Response.fromStream(streamedResp);
    } else {
      var msgBody = contentType == "application/x-www-form-urlencoded"
          ? formParams
          : serialize(body);

      final doRequest = () async {
        switch (method) {
          case "POST":
            return client.post(url, headers: headerParams, body: msgBody);
          case "PUT":
            return client.put(url, headers: headerParams, body: msgBody);
          case "DELETE":
            return client.delete(url, headers: headerParams);
          case "PATCH":
            return client.patch(url, headers: headerParams, body: msgBody);

          default:
            return client.get(url, headers: headerParams);
        }
      };
      response = await doRequest();
    }
    if (response.statusCode >= 400) {
      throw ApiException.response(response.statusCode, response.body,
          builder: RequestBuilder()..path = path);
    } else {
      return response;
    }
  }

  /// Update query and header parameters based on authentication settings.
  /// @param authNames The authentications to apply
  Future _updateParamsForAuth(Set<String> authNames,
      List<QueryParam> queryParams, Map<String, String> headerParams) async {
    for (var authName in authNames.orEmpty()) {
      Authentication auth = _authentications[authName];
      if (auth == null) {
        throw ArgumentError("Authentication undefined: " + authName);
      }
      await auth.applyToParams(queryParams, headerParams);
    }
  }

  void setAccessToken(String accessToken) {
    _authentications.forEach((key, auth) {
      if (auth is OAuth) {
        auth.setAccessToken(accessToken);
      } else if (auth is ApiKeyAuth) {
        auth.apiKey = accessToken;
        auth.apiKeyPrefix = "Bearer";
      }
    });
  }
}
