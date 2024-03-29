import 'package:flutter/cupertino.dart';
import 'package:sunny_sdk_core/auth/auth_user_profile.dart';

abstract class IAuthState {
  bool get isLoggedIn;

  bool get isNotLoggedIn;

  String? get accountId;

  UserDetails? get currentUser;
  set currentUser(UserDetails? currentUser);

  AuthUserProfile? get current;

  Stream<AuthUserProfile> get userStateStream;

  void onPreLogout(Future<bool> onPreLogout());

  Stream<AuthUserProfile?> get onUserChange;

  Future refreshUserProfile(BuildContext context);
}
