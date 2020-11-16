import 'package:sunny_sdk_core/api_exports.dart';

class ThirdPartyApi<C> {
  final String key;
  const ThirdPartyApi(this.key);
  C get credentials => ThirdPartyCreds.get(this);
  set credentials(C credentials) => ThirdPartyCreds.set(this, credentials);
}

extension ThirdPartyCredsApis on _ThirdPartyCreds {
  ThirdPartyApi<String> get googlePlaces =>
      const ThirdPartyApi<String>("googlePlaces");
  ThirdPartyApi<String> get yelp => const ThirdPartyApi<String>("yelp");
  ThirdPartyApi<ClientIdSecretCredentials> get foursquare =>
      const ThirdPartyApi<ClientIdSecretCredentials>("foursquare");
}

final ThirdPartyCreds = _ThirdPartyCreds();

/// Clearinghouse for third-party credentials.  Allows a common gateway where expected credentials reside
class _ThirdPartyCreds {
  final Map<String, dynamic> _credentials = {};

  T get<T>(ThirdPartyApi<T> api) {
    final creds = _credentials[api.key] ??
        illegalState("No credentials found for ${api.key}.  You must set"
            " the credentials using ${api.runtimeType}.credentials = myCredentials");
    return creds as T;
  }

  set<T>(ThirdPartyApi<T> api, T credentials) {
    assert(credentials != null, "Credentials for $api can't be null");
    _credentials[api.key] = credentials;
  }
}

class ClientIdSecretCredentials {
  final String clientId;
  final String clientSecret;

  ClientIdSecretCredentials({this.clientId, this.clientSecret});
}
