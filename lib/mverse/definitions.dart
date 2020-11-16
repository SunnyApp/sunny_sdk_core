// import 'package:m_entity/m_entity.dart';
import 'package:m_entity/m_entity.dart';
import 'package:sunny_dart/sunny_dart.dart';

import 'm_model.dart';

class Definitions {
  Definitions._();

  static const Definition booleanPref =
      Definition.core("booleanPref", PropSchemaType.boolean);
  static const Definition binaryRef =
      Definition.core("binaryRef", PropSchemaType.binaryData);
  static const Definition createdTimestamp =
      Definition.core("createdTimestamp", PropSchemaType.timestamp);
  static const Definition currency =
      Definition.core("currency", PropSchemaType.currency);
  static const Definition date = Definition.core("date", PropSchemaType.date);
  static const Definition dateTime =
      Definition.core("dateTime", PropSchemaType.dateTime);
  static const Definition dayOfWeek =
      Definition.core("dayOfWeek", PropSchemaType.string);
  static const Definition email =
      Definition.core("email", PropSchemaType.email);
  static const Definition familyName =
      Definition.core("familyName", PropSchemaType.string);
  static const Definition flexiDate =
      Definition.core("flexiDate", PropSchemaType.flexiDate);
  static const Definition duration =
      Definition.core("duration", PropSchemaType.duration);
  static const Definition givenName =
      Definition.core("givenName", PropSchemaType.string);
  static const Definition gender =
      Definition.core("gender", PropSchemaType.string);
  static const Definition geoLocation =
      Definition.core("geoLocation", PropSchemaType.geoLocation);
  static const Definition imageUrl =
      Definition.core("imageUrl", PropSchemaType.uri);
  static const Definition jsonPath =
      Definition.core("jsonPath", PropSchemaType.string);
  static const Definition literal =
      Definition.core("literal", PropSchemaType.string);
  static const Definition locale =
      Definition.core("locale", PropSchemaType.string);
  static const Definition location =
      Definition.core("location", PropSchemaType.string);
  static const Definition long = Definition.core("long", PropSchemaType.long);
  static const Definition month =
      Definition.core("month", PropSchemaType.string);
  static const Definition percent =
      Definition.core("percent", PropSchemaType.percent);
  static const Definition phone =
      Definition.core("phone", PropSchemaType.phone);
  static const Definition phoneType =
      Definition.core("phoneType", PropSchemaType.string);
  static const Definition phoneWithExtension =
      Definition.core("phoneWithExtension", PropSchemaType.phoneWithExtension);
  static const Definition prefCategoryRef =
      Definition.core("prefCategoryRef", PropSchemaType.string);
  static const Definition range =
      Definition.core("range", PropSchemaType.range);
  static const Definition searchTerm =
      Definition.core("searchTerm", PropSchemaType.string);
  static const Definition singleValue =
      Definition.core("singleValue", PropSchemaType.string);
  static const Definition textArea =
      Definition.core("textArea", PropSchemaType.string);
  static const Definition timeUnit =
      Definition.core("timeUnit", PropSchemaType.string);
  static const Definition timeZone =
      Definition.core("timeZone", PropSchemaType.string);
  static const Definition titleField =
      Definition.core("titleField", PropSchemaType.string);
  static const Definition updatedTimestamp =
      Definition.core("updatedTimestamp", PropSchemaType.timestamp);
  static const Definition uri = Definition.core("uri", PropSchemaType.uri);
  static const Definition variableName =
      Definition.core("variableName", PropSchemaType.string);
  static const Definition year = Definition.core("year", PropSchemaType.int);

  static const Definition liquidContent =
      Definition.of("sunny", "content", "liquidContent", PropSchemaType.string);
  static const Definition healthInterest =
      Definition.of("truman", "sunny", "healthInterest", PropSchemaType.string);
  static const Definition essentialOilName = Definition.of(
      "truman", "sunny", "essentialOilName", PropSchemaType.string);
  static const Definition essentialOilSku = Definition.of(
      "truman", "sunny", "essentialOilSku", PropSchemaType.string);
  static const Definition sunnyReachOutType =
      Definition.of("slick", "sunny", "reachOutType", PropSchemaType.string);
  static const Definition interest =
      Definition.fact("interest", PropSchemaType.string);
  static const Definition religionType =
      Definition.fact("religionType", PropSchemaType.string);
  static const Definition sportType =
      Definition.fact("sportType", PropSchemaType.string);
  static const Definition mOperationRef =
      Definition.of("mverse", "mthing", "mOperationRef", PropSchemaType.string);

  static const Definition smartDateQueryResult =
      Definition.core("smartDateQueryResult", PropSchemaType.object);
}

class Definition implements HasBaseCode {
  final String uri;
  final String baseCode;
  final PropSchemaType propType;

  const Definition.of(
      String developer, String module, String definition, this.propType)
      : assert(propType != null),
        uri =
            "mverse://schemas/$developer/$module/0.0.1/definitions.json#/definitions/$definition",
        baseCode = "$developer.$module.definitions.$definition";

  const Definition.core(String definition, this.propType)
      : assert(propType != null),
        uri =
            "mverse://schemas/mverse/core/0.0.1/definitions.json#/definitions/$definition",
        baseCode = "mverse.core.definitions.$definition";

  const Definition.fact(String definition, this.propType)
      : assert(propType != null),
        uri =
            "mverse://schemas/sunny/fact/0.0.1/definitions.json#/definitions/$definition",
        baseCode = "sunny.fact.definitions.$definition";

  bool matches(MSchemaProperty prop) {
    return prop.baseCode == this.baseCode || "${prop.uri}" == this.uri;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Definition &&
          runtimeType == other.runtimeType &&
          uri == other.uri;

  @override
  int get hashCode => uri.hashCode;
}

enum PropSchemaType {
  bigString,
  binaryData,
  boolean,
  currency,
  date,
  dateTime,
  double,
  duration,
  email,
  embedded,
  entityList,
  flexiDate,
  geoLocation,
  int,
  long,
  longSelect,
  object,
  percent,
  phone,
  phoneWithExtension,
  list,
  range,
  ref,
  select,
  string,
  stringSelect,
  timestamp,
  uri,
}

extension PropSchemaTypeExtensions on PropSchemaType {
  String get value => this.enumValue;
}
