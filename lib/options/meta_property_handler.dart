// ignore_for_file: unused_import, override_on_non_overriding_member

// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
import 'package:sunny_dart/json.dart';
import 'package:sunny_dart/sunny_dart.dart';

import 'meta_form_context.dart';

abstract class IMetaPropertyHandler<T> {}
// /// Inspects a schema and looks for specialized properties for which we want to build a special UI or component.  Some
// /// fields might be grouped together, for example
// /// [T] The type of data this handler should encounter.
// abstract class MetaPropertyHandler<T> {
//   /// Examines a form, and returns a list of properties that this handler is capable of dealing with, grouped together
//   /// in [HandledPaths].  Each of these field clusters will be passed back to the handler during rendering
//   Iterable<HandledPaths> acceptProperties(JsonPath basePath,
//       MSchemaDefinition definition, Map<JsonPath, MSchemaProperty> available);
//
//   /// Renders a widget (or null) for a provided [HandledPaths] (see [acceptProperties])
//   Iterable<Widget> renderProperty(
//       BuildContext context,
//       IMetaFormContext metaForm,
//       HandledPaths paths,
//       SunnyFormFieldState<T> state,
//       {Key key});
//
//   SunnyFormFieldState<T> castState(SunnyFormFieldState<dynamic> state) {
//     return state.cast();
//   }
// }

// /// A list of json paths - sometimes rendering will handle more than one property at a time
// class HandledPaths {
//   /// The path to this handler - by default, it's the first path that's being handled
//   final JsonPath path;
//
//   /// A base path to be applied
//   final JsonPath basePath;
//
//   /// The paths being handled together
//   final Map<JsonPath, MSchemaProperty> paths;
//
//   final dynamic data;
//
//   /// The handler that is processing these attributes
//   final IMetaPropertyHandler _handler;
//
//   bool get isEmbed => basePath.isNotRoot;
//
//   MSchemaProperty get property {
//     assert(paths.length == 1,
//         "Multiple properties - can only use this getter for single paths");
//     return paths.entries.first.value;
//   }
//
//   JsonPath<T> fullPath<T>() {
//     assert(paths.length == 1,
//         "Multiple properties - can only use this getter for single paths");
//     return (basePath + path).cast<T>();
//   }
//
//   Iterable<Widget> render(BuildContext context, IMetaFormContext metaForm,
//           SunnyFormFieldState state, {Key key}) =>
//       _handler.renderProperty(
//           context, metaForm, this, _handler.castState(state),
//           key: key);
//
//   HandledPaths.ofProperty(MSchemaProperty prop, this.basePath, this._handler,
//       {this.data = const {}})
//       : assert(basePath != null),
//         path = prop.jsonPath,
//         paths = {prop.jsonPath: prop};
//
//   HandledPaths.ofProperties(
//       Iterable<MSchemaProperty> properties, this.basePath, this._handler,
//       {this.data = const {}})
//       : assert(basePath != null),
//         paths = mapOf(properties, keyOf: (p) => p.jsonPath),
//         path = properties.first.jsonPath;
// }
