import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/services.dart';

class RecordEvent<D extends Object> with EquatableMixin {
  final D payload;
  final RecordEventType eventType;

  const RecordEvent(this.payload, this.eventType);

  @override
  List<Object> get props {
    return [eventType, payload];
  }
}

enum RecordEventType { create, delete, update }

class RecordEventService with LoggingMixin, LifecycleAwareMixin {
  final StreamController<RecordEvent> _controller;

  RecordEventService() : _controller = StreamController.broadcast() {
    this.registerDisposer(() => _controller.close());
  }

  Stream<RecordEvent> get events => _controller.stream;

  void publish<D extends Object>(D payload, RecordEventType type) {
    _controller.add(RecordEvent<D>(payload, type));
  }
}

extension StreamOfEventExt<D extends Object> on Stream<RecordEvent<D>> {
  Stream<RecordEvent<DD>> recordType<DD extends Object>() =>
      where((event) => event is RecordEvent<DD>).cast<RecordEvent<DD>>();
  Stream<RecordEvent<D>> get delete =>
      where((event) => event.eventType == RecordEventType.delete);
  Stream<RecordEvent<D>> get create =>
      where((event) => event.eventType == RecordEventType.create);
  Stream<RecordEvent<D>> get update =>
      where((event) => event.eventType == RecordEventType.update);
}
