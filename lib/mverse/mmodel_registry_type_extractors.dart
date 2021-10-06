import 'm_model.dart';

String? extractMverseType(Map<String, dynamic> map, {MSchemaRef? fallbackType}) {
  var mtype = map["mtype"] as String?;
  if (mtype == null) {
    final mmeta = map["mmeta"];
    if (mmeta != null) {
      mtype = mmeta["mtype"] as String?;
    }
  }

  mtype ??= fallbackType?.toString();
  return mtype;
}
