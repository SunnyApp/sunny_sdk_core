import 'dart:core';

import 'package:collection_diff/collection_diff.dart';
import 'package:flexidate/flexidate.dart';
import 'package:sunny_dart/extensions/lang_extensions.dart';
import 'package:sunny_dart/helpers/functions.dart';
import 'package:sunny_dart/helpers/strings.dart';
import 'package:sunny_dart/json.dart';
import 'package:sunny_dart/json/map_model.dart';
import 'package:sunny_sdk_core/api_exports.dart';
import 'package:timezone/timezone.dart';

import 'entity_extensions.dart';
import 'mmodel_registry.dart';

/// Represents an entity defined by a json-schema.
///
/// In memory, the values are stored in the [wrapped] property, which is essentially a map of json values.  A [MModel]
/// is a non-persisted entity, where as [MEntity] represents a persisted entity that has an ID
abstract class MModel with DiffDelegateMixin implements Entity, MapModel {
  final Map<String, dynamic> wrapped;

  MModel clone() =>
      illegalState("Mutation not supported for base MModel.  Perhaps you are "
          "attempting to mutate an abstract class?");

  // ignore: avoid_unused_constructor_parameters
  MModel(Map<String, dynamic>? values, {MSchemaRef? mtype, bool? update})
      : wrapped = values ?? <String, dynamic>{} {
    if (mtype?.value.isNotNullOrBlank == true) {
      if (this is MEntity) {
        if (wrapped["mmeta"] == null) {
          wrapped["mmeta"] = {};
        }
        if (wrapped["mmeta"]["mtype"] == null) {
          wrapped["mmeta"]["mtype"] = mtype!.value;
        }
      } else {
        if (wrapped["mtype"] == null) {
          wrapped["mtype"] = mtype!.value;
        }
      }
      _mtype = mtype;
    }
  }

  /// For [Diffable]
  dynamic get diffSource => wrapped;

  MSchemaRef? _mtype;

  /// For [Diffable]
  dynamic get diffKey => id;

  String? get id => illegalState("Not implemented $runtimeType.id");

  MKey? get mkey =>
      mkeyOrNull ?? illegalState("Not implemented $runtimeType.mkey");

  RecordKey? get recordKey => null;

  MKey? get mkeyOrNull => null;

  MSchemaRef get mtype {
    return _mtype ??=
        (mkeyOrNull?.mtype ?? MSchemaRef.fromJson(wrapped["mtype"])!);
  }

  /// There are some weird cases where collections aren't synced properly with the underlying json.  This will
  /// overwrite the json with the latest value of the variable.
  void sync([Set<String>? fields]) {
    fields ??= this.mfields;
    fields.forEach((f) {
      final v = this[f];
      if (v is Iterable || v is Map) {
        this[f] = v;
      }
    });
  }

  void prune(Set<String> fields) {
    fields.forEach((f) {
      final v = this[f];
      if (v == null || v == "") {
        wrapped.remove(f);
      }
    });
  }

  bool has(String fieldName) {
    return wrapped.containsKey(fieldName);
  }

  Set<String> get mfields => const {};

  modified() {}

  dynamic get(String name) {
    return this[name];
  }

  takeFrom(source) => illegalState("Not supported takeFrom");

  void takeFromMap(Map<String, dynamic>? from, {bool copyEntries = true}) {
    if (copyEntries == true && from != null) {
      this.wrapped.addAll(from);
    }
  }

  static MModel? fromJson(json) {
    return mmodelRegistry.instantiate(json: json);
  }

  T? getByPath<T>(JsonPath path) {
    dynamic value = this;
    for (var segment in path.segments) {
      if (value is MModel) {
        value = value[segment];
      } else if (value is Map) {
        value = value[segment];
      } else {
        throw Exception(
            "Illegal path: $path at segment $segment.  Expected Map or MModel but found ${value.runtimeType}");
      }
      if (value == null) {
        return null;
      }
    }
    return value as T?;
  }

  T? jpath<T>(JsonPath<T> path, [T? value]) {
    if (value != null) {
      setByPath(path, value);
      return value;
    } else {
      return getByPath(path) as T?;
    }
  }

  T? call<T>(final key) {
    return (key is JsonPath) ? getByPath<T>(key) : (this["$key"] as T?);
  }

  dynamic setByPath<T>(JsonPath<T> path, T? value) {
    if (value == "") value = null;
    final lastSegment = path.last;
    final parents = path.chop;
    dynamic container = this;
    for (var segment in parents.segments) {
      container = container.get(segment);
      if (container == null) {
        throw Exception(
            "Missing container in heirarchy.  Full path: $path.  Error found at segment $segment");
      }
    }
    if (value == null && container is Map) {
      container.remove(lastSegment);
    } else {
      container[lastSegment] = value;
    }
  }

  /// For RouteParams - move at some point?
  Map<String, dynamic> toMap() => wrapped;

  dynamic operator [](key) => wrapped[key];

  operator []=(String key, value) => wrapped[key] = value;

  @override
  int get hashCode {
    return equalsChecker.hash(wrapped);
  }

  @override
  bool operator ==(other) {
    if (other is! MModel) return false;
    final isEqual = equalsChecker.equals(wrapped, other.wrapped);
    return other is MModel && isEqual;
  }

  Set<JsonPath> get ignoredPaths => const {};
}

abstract class HasMverseMeta {
  MMeta get mmeta;
}

abstract class HasBaseCode {
  String? get baseCode;
}

extension MEntityEquality on MEntity {
  bool equalsByDateModified(other) {
    return identical(this, other) ||
        other is MEntity &&
            runtimeType == other.runtimeType &&
            mkey == other.mkey &&
            mmodified == other.mmodified;
  }

  int hashCodeByDateModified() => hashOf(mmodified, mkeyOrNull);

  get diffSourceByDateModified => {
        "id": id,
        "mmodified": mmeta.mmodified,
      };
}

/// Represents an entity defined by a json-schema that's backed by json value using the [wrapped] field.  A [MModel]
/// is a non-persisted entity, where as [MEntity] represents a persisted entity that has an ID
abstract class MEntity extends MModel implements HasMverseMeta {
  MEntity(Map<String, dynamic> wrapped, {MSchemaRef? mtype, bool? update})
      : super(wrapped, mtype: mtype, update: update);

  MMeta? _mmeta;

  MMeta get mmeta {
    return _mmeta ??= MMeta.fromJson(wrapped["mmeta"])!;
  }

  set mmeta(MMeta mmeta) {
    _mmeta = mmeta;
  }

  MKey? get mkey => mmeta.mkey;

  MKey? get mkeyOrNull => mmeta.mkey;

  RecordKey? get recordKey => mkeyOrNull?.recordKey;

  String? get id => mmeta.mkey?.value;

  static MEntity? fromJson(json) {
    return mmodelRegistry.instantiate(json: json);
  }

  /// For [Diffable]
  dynamic get diffSource => {
        "id": id,
        "mmodified": mmeta.mmodified,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is MEntity &&
          runtimeType == other.runtimeType &&
          mkey == other.mkey &&
          mmodified == other.mmodified;

  @override
  int get hashCode => (mmodified?.hashCode ?? 31) ^ (mkeyOrNull.hashCode);

  Map<String, dynamic> toMap() => wrappedOrEmpty;
}

abstract class Entity {
  static MKey? toId(Entity _) => _.mkey;

  MKey? get mkey;

  dynamic clone();

  void takeFrom(dynamic source);
}

class RecordKey extends MLiteral<String> {
  final String domainId;
  final String mxid;

  RecordKey(this.domainId, this.mxid) : super("$domainId:$mxid");

  static RecordKey? fromJson(json, {String? fallbackDomainId}) {
    if (json == null) return null;
    if (json is RecordKey) return json;
    if (json is MKey) return json.recordKey;
    final _json = "$json";
    if (_json.contains("/")) {
      return MKey.parsed("$json")!.recordKey;
    } else {
      return _parse(_json, fallbackDomainId: fallbackDomainId);
    }
  }

  static RecordKey? _parse(json, {String? fallbackDomainId}) {
    if (json is RecordKey) return json;
    if (json == null) return null;
    final keyParts = "$json".split(":");
    String? domainId;
    String mxid = keyParts.last;
    if (keyParts.length == 2) {
      domainId = keyParts.first;
    }
    domainId ??= fallbackDomainId;
    return RecordKey(domainId!, mxid);
  }
}

/// Inside the sunny datastore, each record is identified by a key that provides 3 parts:
/// 1) its type, which consists of developer/module/artifact/version/type
/// 2) its domainId, which is the system of origin
/// 3) its external id
class MKey extends MLiteral<String> {
  final MSchemaRef mtype;
  final String domainId;
  final String mxid;

  const MKey(this.mtype, this.domainId, this.mxid)
      : super("$mtype/$domainId:$mxid");

  MKey.fromRecordKey(this.mtype, RecordKey rk)
      : domainId = rk.domainId,
        mxid = rk.mxid,
        super("$mtype/$rk");

  MKey.fromType(MSchemaRef mtype, String mxid, [String? domainId])
      : this(mtype, domainId ?? mtype.domainId, mxid);

  static MKey? parsed(String? value, {MSchemaRef? mtype}) =>
      _parse(value, mtype: mtype)!;

  static MKey? fromJson(value, {MSchemaRef? mtype}) {
    final v = value;
    if (v is MKey) return v;
    if (value == null) return null;
    return _parse("$value", mtype: mtype)!;
  }

  RecordKey get recordKey => RecordKey(domainId, mxid);

  static MKey? _parse(String? value, {MSchemaRef? mtype}) {
    if (value.isNullOrBlank) return null;
    assert(value!.contains("/") || mtype != null,
        "Invalid mkey.  Expected [type/domain:mxid] but found $value");
    final List<String> parts = value?.split("/") ?? [];
    mtype ??= MSchemaRef.parsed(parts[0]);
    final rk =
        RecordKey.fromJson(parts.last, fallbackDomainId: mtype?.domainId);
    return MKey.fromRecordKey(mtype!, rk!);
  }
}

abstract class MMeta {
  MKey? get mkey;

  MSchemaRef? get mtype;

  DateTime? get mmodified;

  String? get maccount;

  bool get isDeleted;

  set isDeleted(bool isDeleted);

  static MMeta? fromJson(dyn) {
    if (dyn == null) return null;
    final json = (dyn as Map).cast<String, dynamic>();
    final mtype = MSchemaRef.fromJson(json["mtype"] as String?);
    return _MMeta(
        mkey: MKey.parsed(json["mkey"] as String?, mtype: mtype),
        mtype: mtype,
        mmodified: withString([json["mmodified"] as String], DateTime.parse),
        maccount: json["maccount"] as String?,
        isDeleted: json["isDeleted"] == true);
  }

  factory MMeta(
      {MKey? mkey,
      MSchemaRef? mtype,
      DateTime? mmodified,
      String? maccount,
      bool isDeleted = false}) {
    return _MMeta(
        mkey: mkey,
        mtype: mtype,
        mmodified: mmodified,
        maccount: maccount,
        isDeleted: isDeleted);
  }
}

class _MMeta implements MMeta {
  final MKey? mkey;
  final MSchemaRef? mtype;
  final DateTime? mmodified;
  final String? maccount;
  bool isDeleted;

  _MMeta(
      {this.mkey,
      this.mtype,
      this.mmodified,
      this.maccount,
      this.isDeleted = false});
}

class MModuleRef extends MLiteral<String> {
  final String module;
  final String developer;
  final String version;

  const MModuleRef.ofParts(this.developer, this.module, this.version)
      : super("$developer.$module.$version");

  MOperationRef operation(String name) => MOperationRef.ofNamed(this, name);
}

class MSchemaTypes {
  MSchemaTypes._();

  static const ephemeral = "ephemeral";
  static const mverse = "mverse";
  static const mvext = "mvext";
}

/// A reference that points to a versioned json-schema for an entity
class MSchemaRef extends MArtifactRef implements HasBaseCode {
  MSchemaRef.ofNamed(MModuleRef module, String schemaName, String type)
      : this(module.developer, module.module, schemaName, module.version, type);

  static MSchemaRef? fromJson(json) => MSchemaRef.parsed(json?.toString());

  static MSchemaRef? parsed(String? value) {
    if (value == null) return null;
    return MSchemaRef._(MArtifactRef._parsed(value));
  }

  const MSchemaRef(String developer, String module, String artifactId,
      String version, String type)
      : super(developer, module, schema, artifactId, version, type);

  const MSchemaRef.ephemeral(
      String developer, String module, String artifactId, String version)
      : super(developer, module, schema, artifactId, version,
            MSchemaTypes.ephemeral);

  MSchemaRef._(List<String> parts) : super._(schema, parts);

  bool get isAbstract => type?.toLowerCase() == "abstract";

  toJson() => value;

  @override
  String get baseCode => "$developer.$module.$artifactId";

  MOperationRef get create {
    final operationName = "${artifactId}Create";
    return MOperationRef(developer, module, operationName, version);
  }

  MOperationRef get list {
    final operationName = "${artifactId}List";
    return MOperationRef(developer, module, operationName, version);
  }

  MModel? newInstance([json]) {
    return mmodelRegistry.instantiate(
        json: json ?? <String, dynamic>{}, type: this);
  }

  RecordKey? recordKey(String id) => mkey(id)?.recordKey;

  MKey? mkey(id) {
    if (id is MKey) return id;
    if (id is RecordKey) return MKey(this, id.domainId, id.mxid);
    if (id == null) return null;
    return MKey.parsed(id.toString(), mtype: this);
  }
}

List<Uri> parseUris(uris) {
  return [...(uris as Iterable).map((uri) => Uri.parse(uri.toString()))];
}

/// A reference that points to a versioned json-schema for an operation or action
class MOperationRef extends MArtifactRef {
  MOperationRef.ofNamed(
    MModuleRef module,
    String operationName, [
    String type = "default",
  ]) : this(module.developer, module.module, operationName, module.version,
            type);

  static MOperationRef? fromJson(json) => MOperationRef.parsed(json.toString());

  static MOperationRef? parsed(String? value) {
    if (value == null) return null;
    return MOperationRef._(MArtifactRef._parsed(value));
  }

  const MOperationRef(
      String? developer, String? module, String artifactId, String? version,
      [String type = "default"])
      : super(developer, module, operation, artifactId, version, type);

  MOperationRef._(List<String> parts) : super._(operation, parts);

  toJson() => value;

  String? get operationName => artifactId;

  /// Fetches (or uses a cached) schema from the server.  This would be a good target for an extension function
  /// if/when dart does that

}

const operation = "operation";
const schema = "schema";

abstract class MArtifactRef extends MLiteral<String> {
  final String? developer;
  final String? module;
  final String? artifactId;
  final String? version;
  final String? type;
  final String artifactType;

  const MArtifactRef(this.developer, this.module, this.artifactType,
      this.artifactId, this.version, this.type)
      : super("$developer:$module:$artifactType:$artifactId:$version@$type");

  MArtifactRef.parsed(String artifactType, String value)
      : this._(artifactType, _parsed(value));

  static List<String> _parsed(String value) {
    final s1 = value.split("@");
    final s2 = s1[0].split(":");
    return [...s2, s1[1]];
  }

  MArtifactRef._(String artifactType, List<String> parts)
      : this(
          parts.get(0),
          parts.get(1),
          artifactType,
          parts.get(3),
          parts.get(4),
          parts.get(5),
        );

  String get relativeSchemaUri {
    return "/$developer/$version/$module/$artifactId/$type/$artifactType";
  }

  String get fullUri {
    return "mverse://${type}s$relativeSchemaUri";
  }

  String get relativeSchemaBaseUri {
    return "/$developer/$version/$module/$artifactId/$type";
  }
}

jsonLiteral(element) {
  if (element is MModel) {
    return element.wrapped;
  } else if (element is MLiteral) {
    return element.value;
  } else if (element is DateTime) {
    return element.toUtc().toIso8601String();
  } else if (element is Uri) {
    return element.toString();
  } else if (element is TimeZone) {
    return element.abbr;
  } else if (element is Location) {
    return element.name;
  } else if (element is double) {
    return element;
  } else if (element is Duration) {
    return "$element";
  } else if (element is TimeSpan) {
    return "$element";
  } else if (element is bool) {
    return element;
  } else if (element is int) {
    return element;
  } else if (element is String) {
    return element;
  } else if (element is Iterable) {
    return element.map((item) => jsonLiteral(item)).toList();
  } else if (element is Map) {
    return element
        .map((key, value) => MapEntry(jsonLiteral(key), jsonLiteral(value)));
  } else {
    return element;
  }
}
