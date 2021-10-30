import 'package:sunny_sdk_core/model_exports.dart';

void setDeep(Object container, JsonPath path, value) {
  if (value == "") value = null;
  final lastSegment = path.last;
  final parents = path.chop;
  for (var segment in parents.segments) {
    final found = ((container as dynamic)[segment]);
    if (found == null) {
      throw Exception("Missing container in heirarchy.  Full path: $path.  Error found at segment $segment");
    } else {
      container = found as Object;
    }
  }
  if (value == null && container is Map) {
    container.remove(lastSegment);
  } else {
    (container as dynamic)[lastSegment] = value;
  }
}
