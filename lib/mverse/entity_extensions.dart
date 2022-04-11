// import 'package:sunny_dart/helpers.dart';

import 'package:sunny_dart/helpers/functions.dart';

import 'm_model.dart';

class EntityExtensions {}

extension MSchemaRefExtensions on MSchemaRef {
  String get domainId => baseCode;
}

extension HasMMetaExt on HasMverseMeta {
  DateTime? get mmodified => mmeta.mmodified;

  MKey? get mkeyOrNull => mmeta.mkey;

  MSchemaRef? get mtype => mmeta.mtype;

  /// Contains just the domainId and the mxid (no type)
  RecordKey? get recordKey => mkeyOrNull?.recordKey;

  /// A fully qualified key that includes the type
  String? get qualifiedKey => mkeyOrNull?.value;
}

/// Fields in the json payload that are metadata (not values)
const metaFields = {"mtype", "mmeta"};

extension MModelExt on MModel? {
  Map<String, dynamic> get wrappedOrEmpty =>
      this?.wrapped ?? <String, dynamic>{};

  /// Returns the json payload, but omits any metadata values
  Map<String, dynamic> get wrappedValues {
    final values = <String, dynamic>{};
    this?.wrapped.forEach((key, value) {
      if (!metaFields.contains(key)) {
        values[key] = value;
      }
    });

    return values;
  }
}

extension ObjectBaseCodeExtension on Object? {
  String? get baseCode {
    final self = this;
    if (self == null) return null;
    if (self is HasBaseCode) {
      return self.baseCode;
    } else if (self is String) {
      return self;
    }
    return illegalState("Must be HasBaseCode to get baseCode");
  }
}

extension MKeyExt on MKey {
  String get debugName {
    return "${mtype.baseCode}/$mxid";
  }
}
