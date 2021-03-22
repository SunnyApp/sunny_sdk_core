import 'package:sunny_sdk_core/auth/auth_user_profile.dart';

abstract class IAuthState {
  bool get isLoggedIn;

  bool get isNotLoggedIn;

  String? get accountId;

  UserDetails? get currentUser;

  AuthUserProfile? get current;

  Stream<AuthUserProfile> get userStateStream;
}
