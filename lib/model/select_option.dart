import 'package:collection_diff/diff_equality.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_dart/typedefs.dart';

/// A builder that passes in whether or not the current suggested item is the one that's presently selected.
typedef SelectionWidgetBuilder = Widget Function(
    BuildContext context, bool isSelected);

//Future<KeyedOption<K, V>> openPicker<K, V>(BuildContext context,
//    {title, content, @required Set<KeyedOption<K, V>> options}) async {
//  final intl = SunnyL10n.of(context);
//  options = options.toSet();
//  return await showPlatformBottomSheet<KeyedOption<K, V>>(
//      context: context,
//      builder: (context) => PlatformBottomSheet(
//            title: textOrNull(title),
//            content: textOrNull(content),
//            actions: [
//              ...options.map(
//                (KeyedOption<K, V> option) {
//                  return PlatformBottomSheetAction(
//                    child: PlatformListTile(
//                      card: false,
//                      backgroundColor: Colors.transparent,
//                      padding: EdgeInsets.zero,
//                      margin: EdgeInsets.zero,
//                      title: textOrNull(option.label),
//                      leading:
//                          (option.icon is IconData) ? iconOrNull(option.icon as IconData) : (option.icon as Widget),
//                      subtitle: textOrNull(option.subtitle?.first), // Probably not idea to pick the first of the array.  not sure why the subtile is a list and not string.
//                    ),
//                    onPressed: () => Navigator.pop(context, option),
//                  );
//                },
//              ),
//            ],
//            cancelButton: PlatformBottomSheetAction(
//              isDefaultAction: true,
//              child: Text(intl.cancelLabel),
//              ios: (_) => CupertinoBottomSheetActionData(isDefaultAction: true),
//              onPressed: () => Navigator.pop(context),
//            ),
//          ));
//}

abstract class IKeyedOptionsHandler<K, V> {}

class KeyedContextSwitchOption<K, V> extends _KeyedOption<K, V> {
  KeyedContextSwitchOption(
    K key,
    V value, {
    @required String label,
    @required this.onSelect,
    icon,
    List subtitle,
    String selection,
    List<String> extraTokens,
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
    @required String label,
    this.adhocCreator,
    icon,
    List subtitle,
    String selection,
    List<String> extraTokens,
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

  final KeyedAdhocOptionCreator<K, V> adhocCreator;

  bool get hasAdhocCreator => adhocCreator != null;

  Future<V> runAdhocCreator(BuildContext context) async {
    return await adhocCreator.call(context, this);
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

class AdhocOption<V> extends KeyedAdhocOption<V, V> {
  AdhocOption(
    V value, {
    @required String label,
    icon,
    List subtitle,
    KeyedAdhocOptionCreator<V, V> adhocCreator,
    String selection,
    List<String> extraTokens,
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

typedef AdhocOptionCreator<T> = Future<T> Function(
    BuildContext context, AdhocOption<T> option);
typedef KeyedAdhocOptionCreator<K, T> = Future<T> Function(
    BuildContext context, KeyedAdhocOption<K, T> option);

abstract class Option<V> extends KeyedOption<V, V> {
  static Option<String> ofString(String value) => _Option.ofString(value);

  static Option<T> ofValue<T>(T key, {String label}) {
    // ignore: can_be_null_after_null_aware
    return _Option<T>(key, label: label ?? key?.toString().toTitle());
  }

  static KeyedOption<K, V> keyed<K, V>(
    K key,
    V value, {
    String label,
    List subtitle,
    List<String> extraTokens,
    String selection,
    Widget icon,
  }) =>
      _KeyedOption(key, value,
          label: label,
          subtitle: subtitle,
          icon: icon,
          selection: selection,
          extraTokens: extraTokens);

  factory Option(
    V value, {
    @required String label,
    icon,
    List subtitle,
    String selection,
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
    @required String label,
    icon,
    List subtitle,
    String selection,
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
    String label,
    icon,
    List subtitle,
    String selection,
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

  get icon;

  List get subtitle;

  List<String> get extraTokens;
}

class StringOption extends _Option<String> {
  StringOption(
    String value, {
    String label,
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
  final List subtitle;
  final List<String> extraTokens;

  _KeyedOption(
    this.key,
    this.value, {
    @required this.label,
    this.icon,
    this.subtitle,
    @required String selection,
    this.extraTokens = const [],
  })  : assert(label != null),
        selection = selection ?? label;

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
    @required String label,
    icon,
    List subtitle,
    String selection,
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

  static _Option<String> ofString(String value) => _Option(
        "$value",
        label: value.toTitle(),
      );

  @override
  get diffKey => key;
}
