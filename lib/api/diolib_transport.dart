import 'package:dio/dio.dart';
import 'package:pfile/pfile_api.dart';
import 'package:sunny_dart/extensions.dart';

import '../query_param.dart';
import 'api_client_transport.dart';

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
          options: Options(
            method: method!,
            contentType: contentType!,
            headers: headerParams,
          ));
      return ApiResponse(
          _resp.statusCode ?? 500, _resp.data?.toString() ?? 'Unknown error');
    } on DioException catch (e) {
      return ApiResponse(
        e.response?.statusCode ?? 500,
        e.response?.data?.toString() ?? e.message ?? 'Unknown error',
      );
    }
  }

  @override
  Future<ApiStreamResponse> streamAPI(
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
      final _resp = await dio.request<ResponseBody>(url,
          data: _body,
          queryParameters: queryParams,
          options: Options(
            method: method!,
            contentType: contentType!,
            headers: headerParams,
          ));
      var rdata = _resp.data;

      return ApiStreamResponse(_resp.statusCode!, rdata!.stream);
    } on DioException catch (e) {
      return ApiStreamResponse(
        e.response?.statusCode ?? 500,
        Stream.value(
            (e.response?.data?.toString() ?? e.message ?? '').codeUnits),
      );
    }
  }
}
