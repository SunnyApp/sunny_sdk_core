import 'package:http/http.dart';
import 'package:pfile/pfile_api.dart';
import 'package:sunny_dart/extensions.dart';

import '../query_param.dart';
import 'api_client_transport.dart';

class HttpLibTransport extends ApiClientTransport {
  final Client client;
  final String basePath;

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
    basePath ??= this.basePath;

    String queryString = queryParams.isNotEmpty
        ? '?' +
            queryParams.flattened().map((e) => "${e.key}=${e.value}").join('&')
        : '';

    String url = basePath + path + queryString;
    headerParams['Content-Type'] = contentType;
    Response response;
    if (body is MultipartRequest) {
      var request = MultipartRequest(method!, Uri.parse(url));
      request.fields.addAll(body.fields);
      request.files.addAll(body.files);
      request.headers.addAll(body.headers);
      request.headers.addAll(headerParams as Map<String, String>);
      var streamedResp = await client.send(request);
      response = await Response.fromStream(streamedResp);
    } else {
      var msgBody = contentType == "application/x-www-form-urlencoded"
          ? formParams
          : serialize(body);

      final doRequest = () async {
        switch (method) {
          case "POST":
            return client.post(url.toUri()!,
                headers: headerParams as Map<String, String>?, body: msgBody);
          case "PUT":
            return client.put(url.toUri()!,
                headers: headerParams as Map<String, String>?, body: msgBody);
          case "DELETE":
            return client.delete(url.toUri()!,
                headers: headerParams as Map<String, String>?);
          case "PATCH":
            return client.patch(url.toUri()!,
                headers: headerParams as Map<String, String>?, body: msgBody);

          default:
            return client.get(url.toUri()!,
                headers: headerParams as Map<String, String>?);
        }
      };
      response = await doRequest();
    }
    // if (response.statusCode >= 400) {
    //   throw ApiException.response(response.statusCode, response.body,
    //       builder: RequestBuilder()
    //         ..basePath = basePath
    //         ..path = path);
    // } else {
    return ApiResponse(response.statusCode, response.body);
    // }
  }

  HttpLibTransport({
    required this.client,
    required this.basePath,
  });
}
