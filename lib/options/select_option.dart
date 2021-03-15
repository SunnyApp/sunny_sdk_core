import 'dart:async';

import 'package:collection_diff/diff_equality.dart';
import 'package:sunny_dart/sunny_dart.dart';

/// A builder that passes in whether or not the current suggested item is the one that's presently selected.
// typedef SelectionWidgetBuilder = Widget Function(
//     BuildContext context, bool isSelected);

abstract class IKeyedOptionsHandler<K, V> {
  FutureOr<V> loadValue(K key);
  String get key;
  bool get canShowAll;

  IKeyedOptionsHandler<KK, VV> cast<KK, VV>();
  const IKeyedOptionsHandler();
}

/// Selects the given option
typedef SelectOption<K, T> = void Function(KeyedOption<K, T> input);

// typedef RenderSuggestionTile<K, T> = Widget Function(
//   BuildContext context,
//   KeyedOption<K, T> suggestion, {
//   required bool isSelected,
//   required SelectOption<K, T> selectOption,
//   VoidCallback? onTap,
// });

abstract class TypeaheadOptionsAndHandler<K, T>
    implements TypeaheadHandler<K, T>, TypeaheadOptions {
  const TypeaheadOptionsAndHandler();
}

enum OptionValueType { key, value }
enum TypeaheadFocusMode { showAll, showAllAndClear, showFiltered, none }

abstract class TypeaheadOptions {
  /// Gets the placeholder text, given a selected option
  String? get placeholder => null;

  String get noOptionsLabel => "Type a value";

  dynamic get prefixIcon => null;

  TypeaheadFocusMode get focusMode => TypeaheadFocusMode.showAll;

  bool get showExpand;

  OptionValueType get valueType;
}

/// Contains all the view-related concerns for integrating [KeyedOption] handlers into typeahead fields
abstract class TypeaheadHandler<K, T> {
  /// Gets the selected text that shows up in the
  String getSelection(KeyedOption<K, T> selectedOption);

  /// Renders the suffix for the selected item in the form control
  R renderSelectedItemSuffix<C, R>(C context, KeyedOption<K, T> selected,
      {required SelectOption<K, T> selectOption});

  /// Renders the suggested tile in the list of options
  R renderSuggestionTile<C, R>(
    C context,
    KeyedOption<K, T> suggestion, {
    required bool isSelected,
    required SelectOption<K, T> selectOption,
    void onTap()?,
  });

  R wrapSuggestionTile<R>(R tile);

  const TypeaheadHandler();
}

class KeyedContextSwitchOption<K, V> extends _KeyedOption<K, V> {
  KeyedContextSwitchOption(
    K key,
    V value, {
    required String label,
    required this.onSelect,
    icon,
    List? subtitle,
    String? selection,
    List<String>? extraTokens,
  }) : super(
          key,
          value,
          label: label,
          icon: icon,
          subtitle: subtitle,
          selection: selection,
          extraTokens: extraTokens,
        );

  final Getter<IKeyedOptionsHandler<K, V>> onSelect;

  @override
  get diffKey => key;

  @override
  get diffSource => key;
}

typedef KeyedAdhocBuilder<K, V> = KeyedAdhocOption<K, V> Function(
    String message);

class KeyedAdhocOption<K, V> extends _KeyedOption<K, V> {
  KeyedAdhocOption(
    K key,
    V value, {
    required String label,
    this.adhocCreator,
    icon,
    List? subtitle,
    String? selection,
    List<String>? extraTokens,
  }) : super(
          key,
          value,
          label: label,
          icon: icon,
          subtitle: subtitle,
          selection: selection,
          extraTokens: extraTokens,
        );

  static KeyedAdhocOption<String, String> ofString(String value) {
    return KeyedAdhocOption<String, String>(value, value, label: value);
  }

  /// When the user selects the ad-hoc option, if this value is non-null, it will help the user create a "real"

  final KeyedAdhocOptionCreator<K, V>? adhocCreator;

  bool get hasAdhocCreator => adhocCreator != null;

  Future<V> runAdhocCreator(context) async {
    return await adhocCreator!.call(context, this);
  }

  @override
  get diffKey => key;

  @override
  get diffSource => key;
}

/// A more natural way to define adhocs when you have a static class
mixin KeyedAdhocOptionMixin<K, V> {
  KeyedAdhocOption<K, V> createAdhocOption(String title);

  KeyedAdhocBuilder<K, V> get adhocOptionBuilder =>
      (input) => createAdhocOption(input);
}

typedef AdhocOptionCreator<T> = Future<T> Function(
    dynamic context, AdhocOption<T> option);
typedef KeyedAdhocOptionCreator<K, T> = Future<T> Function(
    dynamic context, KeyedAdhocOption<K, T> option);

class AdhocOption<V> extends KeyedAdhocOption<V, V> {
  AdhocOption(
    V value, {
    required String label,
    icon,
    List? subtitle,
    KeyedAdhocOptionCreator<V, V>? adhocCreator,
    String? selection,
    List<String>? extraTokens,
  }) : super(
          value,
          value,
          label: label,
          icon: icon,
          adhocCreator: adhocCreator,
          subtitle: subtitle,
          selection: selection,
          extraTokens: extraTokens,
        );

  static AdhocOption<String> ofString(String value) {
    return AdhocOption<String>(value, label: value);
  }
}

abstract class Option<V> extends KeyedOption<V, V> {
  static Option<String> ofString(String value, {icon}) =>
      _Option.ofString(value, icon: icon);

  static Option<T> ofValue<T>(T key, {String? label}) {
    // ignore: can_be_null_after_null_aware
    return _Option<T>(key, label: (label ?? key?.toString().toTitle())!);
  }

  static KeyedOption<K, V> keyed<K, V>(
    K key,
    V value, {
    required String label,
    List? subtitle,
    List<String>? extraTokens,
    String? selection,
    dynamic icon,
  }) =>
      _KeyedOption(key, value,
          label: label,
          subtitle: subtitle,
          icon: icon,
          selection: selection,
          extraTokens: extraTokens);

  factory Option(
    V value, {
    required String label,
    icon,
    List? subtitle,
    String? selection,
    List<String> extraTokens = const [],
  }) {
    return _Option(
      value,
      label: label,
      icon: icon,
      subtitle: subtitle,
      selection: selection,
      extraTokens: extraTokens,
    );
  }
}

/// The backing model for a drop down option.  Allows us to easily render it as a tile, or in other contexts
abstract class KeyedOption<K, V> implements DiffDelegate {
  factory KeyedOption(
    K key,
    V value, {
    required String label,
    icon,
    List? subtitle,
    String? selection,
    List<String> extraTokens = const [],
  }) =>
      _KeyedOption(
        key,
        value,
        label: label,
        icon: icon,
        subtitle: subtitle,
        selection: selection,
        extraTokens: extraTokens,
      );

  factory KeyedOption.ofToString(
    K key,
    V value, {
    String? label,
    icon,
    List? subtitle,
    String? selection,
    List<String> extraTokens = const [],
  }) =>
      _KeyedOption(
        key,
        value,
        label: label ?? "$value",
        icon: icon,
        subtitle: subtitle,
        selection: selection,
        extraTokens: extraTokens,
      );

  K get key;

  V get value;

  String get label;

  String get selection;

  dynamic get icon;

  List? get subtitle;

  List<String>? get extraTokens;
}

class StringOption extends _Option<String> {
  StringOption(
    String value, {
    String? label,
    dynamic icon,
  }) : super(
          value,
          icon: icon,
          label: label ?? value.toTitle(),
        );
}

/// Default impl of [KeyedOption] - an option that has a key and value
class _KeyedOption<K, V> with DiffDelegateMixin implements KeyedOption<K, V> {
  final K key;
  final V value;
  final String label;
  final String selection;
  final icon;
  final List? subtitle;
  final List<String>? extraTokens;

  _KeyedOption(
    this.key,
    this.value, {
    required this.label,
    this.icon,
    this.subtitle,
    required String? selection,
    this.extraTokens = const [],
  }) : selection = selection ?? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _KeyedOption &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value;

  @override
  int get hashCode => key.hashCode ^ value.hashCode;

  @override
  String toString() {
    return "$key => $value";
  }

  @override
  get diffKey => key;
}

/// Default impl of [Option] - an unkeyed selection
class _Option<V> extends _KeyedOption<V, V>
    with DiffDelegateMixin
    implements Option<V> {
  _Option(
    V value, {
    required String label,
    icon,
    List? subtitle,
    String? selection,
    List<String> extraTokens = const [],
  }) : super(
          value,
          value,
          label: label,
          icon: icon,
          subtitle: subtitle,
          selection: selection,
          extraTokens: extraTokens,
        );

  static _Option<String> ofString(String value, {icon}) => _Option(
        "$value",
        label: value.toTitle(),
        icon: icon,
      );

  @override
  get diffKey => key;
}
