import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:sunny_sdk_core/api_exports.dart';
import 'package:sunny_sdk_core/services.dart';

class RecordEvent with EquatableMixin {
  final String recordType;
  final String recordId;
  final RecordEventType eventType;

  const RecordEvent(this.recordType, this.recordId, this.eventType);

  @override
  List<Object> get props {
    return [recordType, eventType, recordId];
  }
}

enum RecordEventType { create, delete, update }

class RecordEventService with LoggingMixin, LifecycleAwareMixin {
  final StreamController<RecordEvent> _controller;

  RecordEventService() : _controller = StreamController.broadcast() {
    this.registerDisposer(() => _controller.close());
  }

  Stream<RecordEvent> get events => _controller.stream;
  void onCreate(String recordType, String recordId, RecordEventType type) {
    _controller.add(RecordEvent(recordType, recordId, type));
  }
}

extension StreamOfEventExt on Stream<RecordEvent> {
  Stream<RecordEvent> forRecordType(String recordType) => where((event) => event.recordType == recordType);
  Stream<RecordEvent> get delete => where((event) => event.eventType == RecordEventType.delete);
  Stream<RecordEvent> get create => where((event) => event.eventType == RecordEventType.create);
  Stream<RecordEvent> get update => where((event) => event.eventType == RecordEventType.update);
}
