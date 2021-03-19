// import 'package:sunny_dart/json/json_path.dart';
//
// import '../mverse.dart';
//
import 'package:sunny_dart/json/json_path.dart';
import 'package:sunny_sdk_core/mverse.dart';

abstract class ISchemaProperty {
  String? get type;

  String? get path;

  String? get label;

  String? get description;

  Uri? get uri;

  String? get baseCode;

  bool? get isRequired;

  JsonPath get jsonPath;

  bool isType(Definition definition);

  bool get isNotRequired;
}
//
// abstract class IMEntityDefinition implements IMSchemaDefinition {
//   MSchemaRef? get schemaRef;
//
//   MSchemaRef? get parentRef;
// }
//
// abstract class IMSchemaDefinition {
//   Uri? get schemaURI;
//
//   List<IMSchemaProperty>? get properties;
//
//   Map<JsonPath, IMSchemaProperty> get propsByPath;
//
//   IMSchemaProperty? prop(JsonPath path);
//
//   MSchemaRef? get self;
//
//   IMEntityDefinition asEntitySchema();
// }
