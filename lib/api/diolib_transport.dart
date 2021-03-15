import 'package:dio/dio.dart';
import 'package:pfile/pfile_api.dart';
import 'package:sunny_dart/extensions.dart';

import '../query_param.dart';
import '../request_builder.dart';
import 'api_client_transport.dart';
import 'api_exceptions.dart';

extension MultipartFilePFile on PFile {
  MultipartFile toMultipartFile() {
    return MultipartFile(this.openStream(), this.size, filename: this.name!);
  }
}

class DioLibTransport extends ApiClientTransport {
  final Dio dio;
  final String basePath;

  DioLibTransport({required this.basePath})
      : dio = Dio(BaseOptions(baseUrl: basePath));

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

    String url = basePath + path;

    final _body = (contentType == "application/x-www-form-urlencoded" ||
            files.isNotNullOrEmpty)
        ? FormData.fromMap({
            for (var f in files) f.name!: f.toMultipartFile(),
            ...formParams,
          })
        : serialize(body);

    try {
      final _resp = await dio.request<String>(url,
          data: _body,
          queryParameters: queryParams,
          options: Options(
            method: method!,
            contentType: contentType!,
            headers: headerParams,
          ));
      return ApiResponse(_resp.statusCode, _resp.data);
    } on DioError catch (e) {
      throw ApiException.response(e.response?.statusCode ?? 500,
          e.response?.data?.toString() ?? e.message,
          builder: RequestBuilder()
            ..basePath = basePath
            ..path = path);
    }
  }
}
