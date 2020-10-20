import 'package:equatable/equatable.dart';

class UserPrefKey extends Equatable {
  final String name;

  // final String prefix;

  const UserPrefKey(this.name) : assert(name != null && name != '');

  @override
  String toString() => name;

  static UserPrefKey fromQualifiedKey(String prefix, String key) {
    return UserPrefKey(key.substring(prefix.length));
  }

  @override
  List<Object> get props => [name];

  bool startsWith(String token) => name.startsWith(token);
}
