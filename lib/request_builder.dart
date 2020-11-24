import 'package:sunny_sdk_core/api_exports.dart';

class RequestBuilder {
  String path;
  HttpMethod method;
  String basePath;

  final Map<String, Object> queryParams = {};
  final Map<String, Object> pathParams = {};
  Object body;
  final Map<String, String> headerParams = {};
  final Map<String, String> formParams = {};
  Iterable<String> authNames;
  String contentType;

  String get requestUrl {
    String url = joinString((_) {
      _ += basePath;
      _ += requestRelativeUrl;
    }, '');
    return url;
  }

  String get requestRelativeUrl {
    var ps = queryParams.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}');
    String queryString = ps.isNotEmpty ? '?' + ps.join('&') : '';

    var requestPath = path;
    pathParams.forEach((key, value) =>
        requestPath = requestPath.replaceAll("{$key}", "$value"));
    String url = joinString((_) {
      _ += requestPath;
      _ += queryString;
    }, '');
    return url;
  }
}

enum HttpMethod { GET, POST, PUT, PATCH, DELETE }

//extension HttpMethodExtension on HttpMethod {
//  fb.HttpMethod toFirebaseHttpMethod() {
//    if (this == null) return null;
//    switch (this) {
//      case HttpMethod.GET:
//        return fb.HttpMethod.Get;
//      case HttpMethod.POST:
//        return fb.HttpMethod.Post;
//      case HttpMethod.PUT:
//        return fb.HttpMethod.Put;
//      case HttpMethod.PATCH:
//        return fb.HttpMethod.Patch;
//      case HttpMethod.DELETE:
//        return fb.HttpMethod.Delete;
//      default:
//        return fb.HttpMethod.Get;
//    }
//  }
//}
