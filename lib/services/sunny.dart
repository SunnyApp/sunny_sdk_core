import 'dart:async';

import 'package:sunny_dart/helpers.dart';
import 'package:sunny_sdk_core/api.dart';
import 'package:sunny_sdk_core/auth/auth_user_profile.dart';
import 'package:sunny_sdk_core/model/user_pref_key.dart';
import 'package:sunny_sdk_core/model_exports.dart';

import 'resolver_inits.dart';

export 'package:sunny_dart/sunny_get.dart';

abstract class BuildContextResolver<C, W> {
  T resolve<T>(C? context);
  W register(C context, resolverOrList,
      {W? child, Key? key});
}

extension BuildContextResolverExt<C, W> on BuildContextResolver<C, W> {
  W registerSingleton<T>(C context, T item,
      {W? child, Key? key}) {
    return register(context, [Inst.constant(item)], child: child, key: key);
  }

  W registerBuilder<T>(
      C context, T create(C context),
      {C? child, Key? key, InstDispose<T>? dispose}) {
    return register(context, [Inst.factory(create, dispose: dispose)],
        child: child, key: key);
  }
}

extension SunnyCoreCastExt on SunnyGet {
  SunnyCore get core => this as SunnyCore;
}

/// Context holder for sunny-related services
class SunnyCore<C, W> implements SunnyGet {
  SunnyCore({this.resolver});

  BuildContextResolver<C, W>? resolver;
  C? buildContext;

  C _verifyBuildContext<T>() =>
      buildContext ??
      illegalState("No buildContext set yet while resolving $T");
  BuildContextResolver<C, W> _verifyResolver<T>() =>
      resolver ?? illegalState("No resolver set getting $T");

  T call<T>({String? name, C? context}) =>
      _resolveOrError<T>(name, context);
  T get<T>({dynamic context, String? name}) =>
      _resolveOrError<T>(name, context);
  T _resolveOrError<T>(String? name, C? context) =>
      _verifyResolver<T>().resolve<T>(context ?? buildContext) ??
      illegalState("Cannot locate ${name ?? "$T"}");
}

extension SunnyCoreEssentialExt on SunnyGet {
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
  UserDetails get currentUser;
  AuthUserProfile get current;
  Stream<AuthUserProfile> get userStateStream;
}
