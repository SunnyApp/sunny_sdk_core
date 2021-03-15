import 'package:sunny_dart/json/json_path.dart';

import '../mverse.dart';

abstract class IMSchemaProperty {
  String? get type;

  String? get path;

  String? get label;

  String? get description;

  Uri? get uri;

  String? get baseCode;

  bool? get isRequired;
}

abstract class IMEntityDefinition implements IMSchemaDefinition {
  MSchemaRef? get schemaRef;

  MSchemaRef? get parentRef;
}

abstract class IMSchemaDefinition {
  Uri? get schemaURI;

  List<IMSchemaProperty>? get properties;

  Map<JsonPath, IMSchemaProperty> get propsByPath;

  IMSchemaProperty? prop(JsonPath path);

  MSchemaRef? get self;

  IMEntityDefinition asEntitySchema();
}
