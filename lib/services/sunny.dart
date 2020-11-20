import 'package:flutter/widgets.dart';
import 'package:sunny_dart/helpers.dart';
import 'package:sunny_sdk_core/api.dart';
import 'package:sunny_sdk_core/auth/auth_user_profile.dart';
import 'package:sunny_sdk_core/model/user_pref_key.dart';

abstract class BuildContextResolver {
  T resolve<T>(BuildContext context);
  // const factory BuildContextResolver.provider() = _ProviderBuildContextResolver;
}


SunnyCore _sunny = SunnyCore._();
SunnyCore get Sunny => _sunny;

set sunny(SunnyCore sunny) {
  assert(sunny != null);
  _sunny = sunny;
}

/// Context holder for sunny-related services
class SunnyCore {
  SunnyCore._();

  BuildContextResolver resolver;
  BuildContext buildContext;

  BuildContext get _verifyBuildContext =>
      buildContext ?? illegalState("No buildContext set yet");
  BuildContextResolver get _verifyResolver =>
      resolver ?? illegalState("No resolver set");

  T call<T>({String name, BuildContext context}) =>
      _resolveOrError<T>(name, context);
  T get<T>({BuildContext context, String name}) =>
      _resolveOrError<T>(name, context);
  T _resolveOrError<T>(String name, BuildContext context) =>
      _verifyResolver.resolve<T>(context ?? _verifyBuildContext) ??
      illegalState("Cannot locate ${name ?? "$T"}");
}

extension SunnyCoreEssentialExt on SunnyCore {
  // SunnyIntl get intl => get();
  IUserPreferencesService get userPreferencesService => get();
  IAuthState get authState => get();
  ApiClient get apiClient => get();
}

abstract class IUserPreferencesService {
  Future<String> get(UserPrefKey key);
  Future<T> set<T>(UserPrefKey key, T value);
}

abstract class IAuthState {
  bool get isLoggedIn;
  bool get isNotLoggedIn;
  String get accountId;
  Stream<AuthUserProfile> get userStateStream;
}
