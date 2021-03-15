import 'dart:collection';

class QueryParams extends MapMixin<String, dynamic> {
  final Map<String, List<String>> _values = {};

  void add(String key, value) {
    if (value == null) return;
    _values.putIfAbsent(key, () => []).add(value.toString());
  }

  Iterable<MapEntry<String, String>> flattened() {
    return _values.entries.expand(
        (element) => element.value.map((v) => MapEntry(element.key, v)));
  }

  @override
  dynamic operator [](Object? key) {
    final v = _values[key as String];
    if (v?.isNotEmpty != true) return null;
    if (v!.length == 1) {
      return v.first;
    } else {
      return v;
    }
  }

  @override
  void operator []=(key, value) {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = [value.toString()];
    }
  }

  @override
  void clear() {
    _values.clear();
  }

  @override
  Iterable<String> get keys => _values.keys;

  @override
  dynamic remove(Object? key) {
    _values.remove(key);
  }
}
