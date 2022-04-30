import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_sdk_core/model.dart';

IMediaService get mediaService => sunny.get<IMediaService>();

abstract class IMediaService {
  ProgressTracker<Uri> uploadMedia(
      final dynamic file, MediaContentType contentType,
      {mediaType,
      String? mediaId,
      ProgressTracker<Uri>? progress,
      bool isDebug});

  /// Gets a relative path to the picture
  FutureOr<String> getMediaPath(MediaContentType contentType, String mediaId,
      {mediaType});

  /// Gets an absolute URI to the picture
  FutureOr<Uri> getMediaUri(MediaContentType contentType, String mediaId,
      {mediaType});
}

abstract class MediaContentType<F extends Object> {
  String get name;

  /// Probably same as name, but not always.
  String get fileType => name;

  int get maxSelections;

  JsonPath get fieldPath;

  Uri? mediaUri(F fact);

  F uriToMedia(Uri uri);

  List<String> get acceptedFileTypes;

  F newContent();

  const MediaContentType();
}

/// Adds equality
abstract class BaseMediaContentType<F extends Object>
    extends MediaContentType<F> with EquatableMixin {
  List get props => [name];

  const BaseMediaContentType() : super();
}
