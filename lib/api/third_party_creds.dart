import 'package:sunny_dart/helpers/functions.dart';

class ThirdPartyApi<C> {
  final String key;
  const ThirdPartyApi(this.key);
  C get credentials => ThirdPartyCreds.get(this);
  set credentials(C credentials) => ThirdPartyCreds.set(this, credentials);
}

extension ThirdPartyCredsApis on _ThirdPartyCreds {
  ThirdPartyApi<String> get googlePlaces =>
      const ThirdPartyApi<String>("googlePlaces");
  ThirdPartyApi<String> get museAI => const ThirdPartyApi<String>("museAI");
  ThirdPartyApi<ClientIdSecretCredentials> get s3 =>
      const ThirdPartyApi<ClientIdSecretCredentials>("s3");
  ThirdPartyApi<ClientIdSecretCredentials> get googleSignIn =>
      const ThirdPartyApi<ClientIdSecretCredentials>("googleSignIn");
  ThirdPartyApi<ClientIdSecretCredentials> get appleSignIn =>
      const ThirdPartyApi<ClientIdSecretCredentials>("appleSignIn");
  ThirdPartyApi<String> get yelp => const ThirdPartyApi<String>("yelp");
  ThirdPartyApi<ClientIdSecretCredentials> get foursquare =>
      const ThirdPartyApi<ClientIdSecretCredentials>("foursquare");
  ThirdPartyApi<String> get ipstack => const ThirdPartyApi<String>("ipstack");
}

final ThirdPartyCreds = _ThirdPartyCreds();

/// Clearinghouse for third-party credentials.  Allows a common gateway where expected credentials reside
class _ThirdPartyCreds {
  final Map<String, dynamic> _credentials = {};

  T get<T>(ThirdPartyApi<T> api) {
    final creds = _credentials[api.key] ??
        illegalState("No credentials found for ${api.key}.  You must set"
            " the credentials using ThirdPartyCreds.${api.key} = myCredentials");
    return creds as T;
  }

  set<T>(ThirdPartyApi<T> api, T credentials) {
    assert(credentials != null, "Credentials for $api can't be null");
    _credentials[api.key] = credentials;
  }
}

class ClientIdSecretCredentials {
  final String? clientId;
  final String? clientSecret;
  final String? redirectUrl;

  ClientIdSecretCredentials(
      {this.clientId, this.clientSecret, this.redirectUrl});
}
