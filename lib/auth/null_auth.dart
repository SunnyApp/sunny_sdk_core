import '../query_param.dart';
import 'authentication.dart';

class NullAuth implements Authentication {
  const NullAuth();

  @override
  void applyToParams(QueryParams query, Map<String, String?> headers) {}

  @override
  get lastAuthentication => null;
}
