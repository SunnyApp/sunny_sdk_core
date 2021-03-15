// ignore_for_file: unused_import, override_on_non_overriding_member

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:sunny_dart/json.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_dart/typedefs.dart';
import 'package:sunny_sdk_core/mverse/entity_extensions.dart';
import 'package:sunny_sdk_core/mverse/m_enum_registry.dart';
import 'package:sunny_sdk_core/services/sunny.dart';

import 'meta_form_context.dart';
import 'meta_property_handler.dart';
import 'select_option.dart';

// final _log = Logger("optionsService");

// typedef AdhocBuilder<T> = AdhocOption<T> Function(String message);

IOptionsService get optionsService => sunny.get();

abstract class IOptionsService {
  void register(IKeyedOptionsHandler prop);

  IKeyedOptionsHandler<K, T> getKeyedHandler<K, T>(Object key,
      {required IMetaFormFieldContext metaContext});

  bool contains<K, T>(Object key);
}
// class OptionsService {
//   Map<String, KeyedOptionsHandler> _optionsHandlers =
//       <String, KeyedOptionsHandler>{};
//
//   register(KeyedOptionsHandler handler) =>
//       _optionsHandlers[handler.key] = handler;
//
//   OptionsService operator +(KeyedOptionsHandler handler) {
//     register(handler);
//     return this;
//   }
//
//   OptionsHandler<T> getHandler<T>(Object key,
//       {@required IMetaFormFieldContext metaContext}) {
//     final _key = key.baseCode;
//     return (_optionsHandlers[_key] as OptionsHandler<T>)
//             ?.withMetaContext(metaContext) ??
//         noopHandler(_key);
//   }
//
//   KeyedOptionsHandler<K, T> getKeyedHandler<K, T>(Object key,
//       {@required IMetaFormFieldContext metaContext}) {
//     final _key = key.baseCode;
//     return (_optionsHandlers[_key] as KeyedOptionsHandler<K, T>)
//             ?.withMetaContext(metaContext) ??
//         noopKeyHandler(_key);
//   }
// }

// const kDefaultNumOptions = 10;
//
// enum OptionMode { suggested, selected }

// /// A base interface for helping to populate drop-downs and typeaheads.  There are a couple of common mixins to cut down
// /// on boilerplate:
// ///
// /// [InMemorySearchOptionsMixin] If you have a list of static options and then want to apply in-memory filtering, use the
// /// [AlwaysFilterSearchOptionsMixin] If you always filter results, and want to force your [listAllOptions] to just execute a
// /// blank search
// abstract class KeyedOptionsHandler<K, T> implements IKeyedOptionsHandler<K, T> {
//   final String key;
//
//   KeyedOptionsHandler(Object key) : key = key.baseCode;
//
//   const KeyedOptionsHandler.ofString(this.key) : assert(key != null);
//
//   /// Whether or not its reasonable to display all options (or at least the first few), without any query input from
//   /// the user.
//   bool get canShowAll;
//
//   /// A list of all options.
//   ///
//   /// Another common use case is to implement [listAllOptions] and then use the [InMemorySearchOptionsMixin] to apply full
//   /// text indexing on the options.  In that case, this function should be overridden
//   FutureOr<List<T>> listAllOptions([int limit]);
//
//   /// Filters the list of all options based on a query - the list of current selections is also provided.
//   FutureOr<List<T>> filter(String query, List currentSelections, int limit);
//
//   KeyedAdhocBuilder<K, T> get adhocOptionBuilder;
//
//   /// Casts a list of inputs as this type
//   List<K> cast(List input) => input?.cast<K>();
//
//   /// Converts a value [T] to a [KeyedOption]
//   KeyedOption<K, T> toOption(T value);
//
//   /// Produces a key, given a value
//   K toKey(T value);
//
//   /// Loads a value given a key - because some options can be suggestive type-aheads, consumers should use
//   /// [StringOptionsHandlerExtension.resolveOption] and [StringOptionsHandlerExtension.resolveAllOptions]
//   FutureOr<T> loadValue(K key);
//
//   /// Creates a copy of this handler, for hte provided context.  Sometimes the behavior of options will change
//   /// based on the surrounding context.
//   KeyedOptionsHandler<K, T> withMetaContext(IMetaFormFieldContext context) =>
//       this;
// }
//
// /// A base class for helping to populate drop-downs and typeaheads.
// ///
// /// This class works with models and tries to remain free of view concerns, but the [Option] class does track title,
// /// subtitle, and selection.
// abstract class OptionsHandler<T> extends KeyedOptionsHandler<T, T> {
//   OptionsHandler(dynamic key) : super(key);
//
//   static OptionsHandler<T> ofEnum<T extends MLiteral<String>>(String key,
//       {String placeholder}) {
//     final values = mEnumRegistry.values<T>(key);
//     return OptionsHandler<T>.ofList(
//       key,
//       canShowAll: true,
//       placeholder: placeholder,
//       toOption: (T key) => Option.ofValue<T>(key),
//       allOptions: [...?values],
//     );
//   }
//
//   static OptionsHandler<String> ofProperty(
//     MSchemaProperty prop, {
//     String placeholder = "Enter an option",
//     List<String> allOptions,
//     @required bool allowAdHoc,
//   }) {
//     if (prop is StringSelectProperty) {
//       allOptions ??= prop.options;
//     }
//     allOptions ??= [];
//     return _OptionsHandler<String>(prop.baseCode,
//         allOptions: allOptions,
//         placeholder: placeholder,
//         canShowAll: true,
//         adhocOptionsBuilder: allowAdHoc == true
//             ? ((item, {context}) => AdhocOption.ofString("$item"))
//             : null,
//         toOption: ((String from) => Option.ofValue(from)));
//   }
//
//   factory OptionsHandler.ofList(
//     key, {
//     String placeholder,
//     Icon inputIcon,
//     bool canShowAll,
//     List<T> allOptions,
//     Mapping<T, Option<T>> toOption,
//     AdhocBuilder<T> adhocOptionsBuilder,
//   }) {
//     return _OptionsHandler(
//       key,
//       placeholder: placeholder,
//       inputIcon: inputIcon,
//       adhocOptionsBuilder: adhocOptionsBuilder,
//       canShowAll: canShowAll,
//       allOptions: allOptions,
//       toOption: toOption ?? ((T value) => Option.ofValue(value)),
//     );
//   }
//
//   static KeyedOptionsHandler<K, V> ofMap<K, V>(
//     key, {
//     String placeholder,
//     Icon inputIcon,
//     bool canShowAll,
//     @required Map<K, V> allOptions,
//     @required Mapping<V, KeyedOption<K, V>> toOption,
//     @required Mapping<V, K> toKey,
//     KeyedAdhocBuilder<K, V> adhocOptionBuilder,
//   }) {
//     return _KeyedOptionsHandler<K, V>(
//       key,
//       adhocOptionBuilder: adhocOptionBuilder,
//       placeholder: placeholder,
//       inputIcon: inputIcon,
//       canShowAll: canShowAll,
//       allOptionsMap: {...?allOptions},
//       toKey: toKey,
//       toOption: (V value) => toOption(value),
//     );
//   }
//
//   @override
//   Option<T> toOption(T value);
//
//   T loadValue(T key) => key;
//
//   /// Creates a copy of this handler, for hte provided context.  Sometimes the behavior of options will change
//   /// based on the surrounding context.
//   OptionsHandler<T> withMetaContext(IMetaFormFieldContext context) => this;
// }
//
//
// class OptionHandlerPair<K, T> {
//   final KeyedOptionsHandler<K, T> baseHandler;
//   final TypeaheadHandler<K, T> viewHandler;
//
//   OptionHandlerPair(this.baseHandler, this.viewHandler);
// }
//
// extension BuildContextOptionService on BuildContext {
//   OptionsService get optionsService {
//     return Provided.get(this);
//   }
// }
