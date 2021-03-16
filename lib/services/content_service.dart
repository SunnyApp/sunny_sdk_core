import 'dart:async';

import 'package:sunny_sdk_core/model/render_mode.dart';
import 'package:sunny_dart/sunny_get.dart';

import 'sunny.dart';

abstract class IContent {}

abstract class ContentServiceSpec<C, W> {
  W render(C context, IContent content, FutureOr onComplete(), RenderMode renderMode);

  FutureOr<bool> isDismissed(IContent iContent);
}

ContentServiceSpec get contentService => sunny.get();
