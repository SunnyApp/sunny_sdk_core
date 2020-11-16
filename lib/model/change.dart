// DO NOT EDIT THIS FILE.  IT IS GENERATED AUTOMATICALLY AND YOUR CHANGES WILL BE OVERWRITTEN

import 'dart:convert';

import 'package:meta/meta.dart'; // ignore: unused_import, directives_ordering
import 'package:sunny_dart/helpers/maps.dart';
import 'package:sunny_dart/json.dart';
import 'package:sunny_sdk_core/mverse.dart';
import 'package:timezone/timezone.dart'; // ignore: unused_import, directives_ordering

class Change extends ChangeBase {
  Change(Map<String, dynamic> wrapped,
      {MSchemaRef mtype = ChangeRef, bool update = true})
      : super(wrapped, mtype: mtype, update: update);

  factory Change.fromJson(wrapped) =>
      wrapped is Change ? wrapped : Change(wrapped as Map<String, dynamic>);

  Change.of({@required String operation, @required String path, String from})
      : super.of(
          operation: operation,
          path: path,
          from: from,
        );

  String get operation => _operation;
  set operation(String operation) {
    this._operation = operation;
    wrapped['operation'] = jsonLiteral(operation);
  }

  String get path => _path;
  set path(String path) {
    this._path = path;
    wrapped['path'] = jsonLiteral(path);
  }

  String get from => _from;
  set from(String from) {
    this._from = from;
    wrapped['from'] = jsonLiteral(from);
  }
}

abstract class ChangeBase extends MModel {
  ChangeBase(Map<String, dynamic> wrapped,
      {MSchemaRef mtype = ChangeRef, @required bool update})
      : super(wrapped, mtype: mtype, update: false) {
    if (update == true) takeFromMap(wrapped, copyEntries: false);
  }

  ChangeBase.fromJson(wrapped)
      : this(wrapped as Map<String, dynamic>, update: true);
  ChangeBase.of(
      {@required String operation, @required String path, String from})
      : super(<String, dynamic>{}, mtype: ChangeRef) {
    if (operation != null) this.operation = operation;
    if (path != null) this.path = path;
    if (from != null) this.from = from;
  }

  String _operation;

  /// Property getter and setter for operation:
  String get operation;
  set operation(String operation);

  String _path;

  /// Property getter and setter for path:
  String get path;
  set path(String path);

  String _from;

  /// Property getter and setter for from:
  String get from;
  set from(String from);

  @override
  String toString() => json.encode(wrapped).toString();
  dynamic toJson() => wrapped;

  operator [](key) {
    switch (key) {
      case "operation":
        return this.operation;
      case "path":
        return this.path;
      case "from":
        return this.from;
      default:
        return wrapped[key];
    }
  }

  operator []=(String key, value) {
    switch (key) {
      case "operation":
        this.operation = value as String;
        break;
      case "path":
        this.path = value as String;
        break;
      case "from":
        this.from = value as String;
        break;
      default:
        wrapped[key] = value;
    }
  }

  @override
  void takeFrom(source) {
    if (source == null) return;
    if (source is Map<String, dynamic>) {
      takeFromMap(source, copyEntries: true);
    } else if (source is MModel) {
      takeFromMap(source?.wrapped, copyEntries: true);
    } else {
      throw ("Can't take values from unknown type ${source.runtimeType}");
    }
  }

  void takeFromMap(Map<String, dynamic> from, {bool copyEntries = true}) {
    if (from == null) return;

    super.takeFromMap(from, copyEntries: copyEntries);
    for (final entry in from.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;
      switch (key) {
        case "operation":
          _operation = value as String;
          break;
        case "path":
          _path = value as String;
          break;
        case "from":
          _from = value as String;
          break;
        default:
          break;
      }
    }
  }

  Change clone() => Change.fromJson(deepCloneMap(wrapped));

  @override
  Set<String> get mfields => ChangeFields.values;
}

class ChangeFields {
  static const operation = "operation";
  static const path = "path";
  static const from = "from";
  static const Set<String> values = {operation, path, from};
}

class ChangePaths {
  static const JsonPath<String> operation =
      JsonPath.internal(["operation"], "/operation");
  static const JsonPath<String> path = JsonPath.internal(["path"], "/path");
  static const JsonPath<String> from = JsonPath.internal(["from"], "/from");
  static final Set<JsonPath> values = {operation, path, from};
}

const ChangeRef =
    MSchemaRef("mverse", "mthing", "change", "0.0.1", "ephemeral");
