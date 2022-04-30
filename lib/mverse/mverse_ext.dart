import 'package:sunny_sdk_core/api_exports.dart';

extension MSchemaRefFactoryExt on MSchemaRef {
  MModel? newInstance([json]) {
    return mmodelRegistry.instantiate(
        json: json ?? <String, dynamic>{}, type: this);
  }
}
