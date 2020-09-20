import 'dart:convert';

import 'package:http/http.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_sdk_core/query_param.dart';
import 'package:sunny_sdk_core/request_builder.dart';

import 'api_exceptions.dart';
import 'api_reader.dart';
import 'auth/api_key_auth.dart';
import 'auth/oauth.dart';
import 'authentication.dart';

class ApiClient {
  String basePath;

  final ApiReader serializer;
  final Client client;

  Map<String, String> _defaultHeaderMap = {};
  Map<String, Authentication> _authentications = {};

  ApiClient(
      {this.basePath = "https://localhost:8080",
      Client client,
      this.serializer,
      Authentication authentication})
      : client = client ?? Client() {
    // Setup authentications (key: authentication name, value: authentication).
    _authentications['Bearer'] =
        authentication ?? ApiKeyAuth("header", "Authorization");
  }

  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  dynamic _deserialize(dynamic value, String targetType) {
    try {
      final deser = this.serializer.getReader(value, targetType);
      if (deser == null) {
        throw ApiException.response(
            500, 'Could not find a suitable class for deserialization');
      }
      return deser(value);
    } catch (e, stack) {
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
        request.basePath,
        request.method.enumValue,
        request.queryParams.mapEntries((k, v) => QueryParam(k, v)),
        request.body,
        request.headerParams,
        request.formParams,
        request.contentType,
        null);
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
      List<String> authNames) async {
    await _updateParamsForAuth(authNames, queryParams, headerParams);

    var ps = queryParams
        .where((p) => p.value != null)
        .map((p) => '${p.name}=${p.value}');
    String queryString = ps.isNotEmpty ? '?' + ps.join('&') : '';

    String url = basePath + path + queryString;

    headerParams.addAll(_defaultHeaderMap);
    headerParams['Content-Type'] = contentType;

    if (body is MultipartRequest) {
      var request = MultipartRequest(method, Uri.parse(url));
      request.fields.addAll(body.fields);
      request.files.addAll(body.files);
      request.headers.addAll(body.headers);
      request.headers.addAll(headerParams);
      var response = await client.send(request);
      return Response.fromStream(response);
    } else {
      var msgBody = contentType == "application/x-www-form-urlencoded"
          ? formParams
          : serialize(body);
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
    }
  }

  /// Update query and header parameters based on authentication settings.
  /// @param authNames The authentications to apply
  Future _updateParamsForAuth(List<String> authNames,
      List<QueryParam> queryParams, Map<String, String> headerParams) async {
    for (var authName in authNames) {
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
