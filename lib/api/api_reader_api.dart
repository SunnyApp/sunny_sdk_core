// import 'package:sunny_sdk_core/mverse/m_model.dart';
import 'package:sunny_sdk_core/mverse/mmodel_registry.dart';

// typedef Deserializer = dynamic Function(dynamic input);
//
// abstract class ApiReader {
//   Deserializer? getReader(final input, String targetType);
//
//   const factory ApiReader.mmodel() = MModelRegistryReader;
// }
//
// class MModelRegistryReader implements ApiReader {
//   const MModelRegistryReader();
//
//   @override
//   Deserializer getReader(input, String targetType) {
//     return (value) => mmodelRegistry.instantiate(
//         json: value, type: MSchemaRef.fromJson(targetType));
//   }
// }
