import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sunny_dart/helpers.dart';
import 'package:sunny_sdk_core/api.dart';
import 'package:sunny_sdk_core/model/user_pref_key.dart';
import 'package:sunny_sdk_core/model_exports.dart';

import 'i_auth_state.dart';
import 'resolver_inits.dart';

export 'package:sunny_dart/sunny_get.dart';

abstract class BuildContextResolver {
  T resolve<T>(BuildContext? context);

  Widget register(BuildContext context, resolverOrList,
      {Widget? child, Key? key});
}

extension BuildContextResolverExt on BuildContextResolver {
  Widget registerSingleton<T extends Object>(BuildContext context, T item,
      {Widget? child, Key? key}) {
    return register(context, [Inst.constant(item)], child: child, key: key);
  }

  Widget registerBuilder<T extends Object>(
      BuildContext context, T create(BuildContext? context),
      {Widget? child, Key? key, InstDispose<T>? dispose}) {
    return register(context, [Inst.factory(create, dispose: dispose)],
        child: child, key: key);
  }
}

extension SunnyCoreCastExt on SunnyGet {
  SunnyCore get core => this as SunnyCore;
}

/// Context holder for sunny-related services
class SunnyCore implements SunnyGet {
  SunnyCore({this.resolver});

  BuildContextResolver? resolver;
  BuildContext? buildContext;

  BuildContextResolver _verifyResolver<T>() =>
      resolver ?? illegalState("No resolver set getting $T");

  T call<T>({String? name, BuildContext? context}) =>
      _resolveOrError<T>(name, context);

  T get<T>({dynamic context, String? name}) =>
      _resolveOrError<T>(name, context as BuildContext?);

  T _resolveOrError<T>(String? name, BuildContext? context) =>
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
