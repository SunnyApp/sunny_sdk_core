import 'package:logging/logging.dart';
import 'package:sunny_dart/helpers/functions.dart';

import 'm_base_model.dart';
import 'm_model.dart';

/// Given a string, returns a function that knows how to instantiate objects of that type
typedef MModelFactoryResolver<M extends MBaseModel> = MModelFactory<M>? Function(String type);

/// Given json, produces an [MBaseModel] of that type
typedef MModelFactory<M extends MBaseModel> = M Function(dynamic json);

String? extractMverseType(Map<String, dynamic> map) {
  var mtype = map["mtype"] as String?;
  if (mtype == null) {
    final mmeta = map["mmeta"];
    if (mmeta != null) {
      mtype = mmeta["mtype"] as String?;
    }
  }

  return mtype;
}

mixin MModelFactoryRegistry {
  Logger get log;

  final Map<String, MModelFactory> _factories = {};

  void register(MSchemaRef type, MModelFactory factory) {
    if (type.value.isNotEmpty != true) {
      return;
    }
    if (_factories.containsKey("$type")) {
      log.info("WARN:  Factory already registered for $type");
    }

    _factories["$type"] = assertNotNull(factory);
  }

  MModelFactory? lookupFactory(String type) => _factories[type];
}
