import 'dart:async';

import 'package:dartxx/json_path.dart';
import 'package:equatable/equatable.dart';
import 'package:sunny_dart/sunny_dart.dart';

IMediaService get mediaService => sunny.get<IMediaService>();

abstract class IMediaService<Reporter> {
  Reporter uploadMedia(final dynamic file, MediaContentType contentType,
      {mediaType, String? mediaId, Reporter? progress, bool isDebug});

  /// Gets a relative path to the picture
  FutureOr<String> getMediaPath(MediaContentType contentType, String mediaId,
      {mediaType});

  /// Gets an absolute URI to the picture
  FutureOr<Uri> getMediaUri(MediaContentType contentType, String mediaId,
      {mediaType});
}

abstract class MediaContentType<F> extends Equatable {
  String get name;

  /// Probably same as name, but not always.
  String get fileType => name;

  int get maxSelections;

  JsonPath get fieldPath;

  Uri? mediaUri(F fact);

  F uriToMedia(Uri? uri);

  List<String> get acceptedFileTypes;

  @override
  List<Object> get props => [name];

  F newContent();

  const MediaContentType();
}
