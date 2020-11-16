import 'package:m_entity/m_entity.dart';
import 'package:sunny_dart/sunny_dart.dart';

import 'meta_property_handler.dart';

abstract class IMetaFormFieldContext {
  MetadataOverrides get overrides;
  List<IMetaPropertyHandler> get extraHandlers;
  Map<String, dynamic> get data;

  T formConfig<T extends MetaFieldConfig>();
}

abstract class IMetaFormContext {
  MetadataOverrides get overrides;
  List<IMetaPropertyHandler> get extraHandlers;
  Map<String, dynamic> get scope;
  bool get isEmbed;
  IMetaFormFieldContext prop(MSchemaProperty property);
  MSchemaDefinition get schema;
  bool get isLoaded;
}

MetadataOverrides meta(
    {String label,
    String pluralLabel,
    String addLabel,
    String editLabel,
    Set<JsonPath> ignoredPaths,
    Map<dynamic, String> labels,
    List<dynamic> sortOrder,
    Map<JsonPath, MetaFieldConfig> formConfig,
//    Map<JsonPath, MetaDateFormatter> metaDateFormatters,
    Map<dynamic, String> placeholders}) {
  return MetadataOverrides.coerced(
      label: label,
      addLabel: addLabel,
      editLabel: editLabel,
      pluralLabel: pluralLabel,
      ignoredPaths: ignoredPaths,
      formConfig: formConfig?.mapValues((_, v) => [v]),
//      metaDateFormatters: metaDateFormatters,
      sortOrder: sortOrder ?? labels?.keys,
      labels: labels,
      placeholders: placeholders);
}

class MetadataOverrides {
  final String label;
  final String addLabel;
  final String editLabel;
  final String pluralLabel;
  final String category;
  final bool isDisabled;
  final Map<JsonPath, String> labels;
  final Map<JsonPath, List<MetaFieldConfig>> formConfig;
  final Map<JsonPath, String> placeholders;
//  final Map<JsonPath, MetaDateFormatter> metaDateFormatters;
  final Set<JsonPath> ignoredPaths;
  final List<JsonPath> sortOrder;

  const MetadataOverrides.empty()
      : labels = const {},
        label = null,
        addLabel = null,
        editLabel = null,
        pluralLabel = null,
        isDisabled = null,
        formConfig = const {},
//        metaDateFormatters = null,
        category = null,
        placeholders = const {},
        sortOrder = const [],
        ignoredPaths = const <JsonPath>{};

  MetadataOverrides.coerced(
      {this.label,
      this.editLabel,
      this.pluralLabel,
      this.isDisabled,
      this.addLabel,
      this.category,
      this.formConfig,
//      this.metaDateFormatters,
      this.ignoredPaths = const {},
      Map<dynamic, String> labels,
      Map<dynamic, String> placeholders,
      Iterable<dynamic> sortOrder})
      : labels = labels?.map((k, v) => MapEntry(JsonPath.of(k), v)) ?? {},
        sortOrder = sortOrder?.map((p) => JsonPath.of(p))?.toList() ?? const [],
        placeholders =
            placeholders?.map((k, v) => MapEntry(JsonPath.of(k), v)) ?? {};

  const MetadataOverrides(
      {this.label,
      this.addLabel,
      this.editLabel,
      this.pluralLabel,
      this.isDisabled,
      this.formConfig = const {},
      this.category,
      this.ignoredPaths = const {},
      this.labels = const {},
//      this.metaDateFormatters = const {},
      this.placeholders = const {},
      this.sortOrder = const []});

  String resolveLabel(JsonPath property, {String fallback}) {
    return labels[property] ?? fallback;
  }

  String resolvePlaceholder(JsonPath property, {String fallback}) {
    return placeholders[property] ?? fallback;
  }

  List<JsonPath> sortProperties(Iterable<JsonPath> source) {
    final toSort = {...?source};
    final sorted = <JsonPath>[];
    for (final p in sortOrder) {
      if (toSort.contains(p)) {
        sorted.add(p);
        toSort.remove(p);
      }
    }
    for (final p in source) {
      // If it's still in the toSort set, then we need to add it (using the original order)
      if (toSort.contains(p)) {
        sorted.add(p);
      }
    }
    return sorted;
  }

  MetadataOverrides operator +(MetadataOverrides other) {
    if (other == null) return this;
    return MetadataOverrides(
        label: other.label ?? this.label,
        addLabel: other.addLabel ?? this.addLabel,
        editLabel: other.editLabel ?? this.editLabel,
        category: other.category ?? this.category,
        isDisabled: other.isDisabled ?? this.isDisabled,
        pluralLabel: other.pluralLabel ?? this.pluralLabel,
        formConfig: other.formConfig.mergeWith(this.formConfig),
        labels: {
          ...?labels,
          ...?other?.labels,
        },
        placeholders: {
          ...?placeholders,
          ...?other?.placeholders,
        },
//        metaDateFormatters: {
//          ...?metaDateFormatters,
//          ...?other?.metaDateFormatters,
//        },
        sortOrder: other?.sortOrder?.ifEmpty(() => this.sortOrder)?.toList(),
        ignoredPaths: {
          ...?ignoredPaths,
          ...?other?.ignoredPaths,
        });
  }
}

/// Marker interface for making configuration changes to widgets
abstract class MetaFieldConfig {
  bool get isDisabled;

  /// Merges these overrides with another
  MetaFieldConfig merge(MetaFieldConfig other);

  static MetaFieldConfig of({bool isDisabled}) {
    return _MetaFieldConfig(isDisabled: isDisabled);
  }
}

class _MetaFieldConfig implements MetaFieldConfig {
  final bool isDisabled;

  @override
  _MetaFieldConfig merge(MetaFieldConfig other) {
    return this.copy(isDisabled: other.isDisabled);
  }

  _MetaFieldConfig copy({
    bool isDisabled,
  }) {
    return _MetaFieldConfig(
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  const _MetaFieldConfig({
    this.isDisabled,
  });
}
