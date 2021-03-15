import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
// import 'package:trippi_app/base.dart';

///
/// The combination of a firebase user + a reliveit user profile.  Most places in the
/// app want to subscribe to auth events after the user profile has been loaded to
/// distinguish from an account that's in the process of being created.
///
/// But, some cases also need access to the underlying firebase authentication, possibly
/// to get a token.
class AuthUserProfile with EquatableMixin {
  final fb.User? fbUser;
  final UserDetails? profile;
  final AuthEventSource source;
  const AuthUserProfile(this.fbUser, this.profile, this.source);
  const AuthUserProfile.empty(this.source)
      : fbUser = null,
        profile = null;

  Future<String> getIdToken({bool forceRefresh = false}) {
    return fbUser!.getIdToken(forceRefresh);
  }

  @override
  List<Object?> get props => [fbUser?.uid, profile?.id];
}

enum AuthEventSource {
  existing,
  error,
  failed,
  initial,
  manual,
  framework,
  postSignup
}

class UserDetails {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String pictureUrl;
  final String firebaseId;
  final dynamic _source;

  UserDetails(this._source, this.id, this.name, this.email, this.pictureUrl,
      this.phone, this.firebaseId);

  P source<P>() {
    return _source as P;
  }
}
