import 'dart:async';

import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:sunny_dart/helpers/disposable.dart';
import 'package:sunny_sdk_core/auth/auth_user_profile.dart';
import 'package:sunny_dart/sunny_get.dart';
import 'package:sunny_sdk_core/services/sunny.dart';

typedef _AsyncCallback = FutureOr Function();

abstract class LifecycleAware {
  FutureOr dispose();
}

abstract class LifecycleAwareBase implements HasDisposers {
  Logger get log;

  void onShutdown(_AsyncCallback callback);

  void onStartup(_AsyncCallback callback);

  bool isShuttingDown();

  Future doShutdown();

  R? exec<R>(R block());

  void registerLoginHooks(IAuthState state);

  void onLogout(AsyncOrCallback onLogout);
  void onLogin(AsyncOrCallback onLogin);

  Future dispose();
}

typedef AsyncOrCallback = FutureOr Function();
mixin LifecycleAwareMixin implements LifecycleAwareBase {
  Stream<AuthUserProfile> get userStateStream =>
      sunny.authState.userStateStream;
  @override
  Logger get log;

  bool _isShuttingDown = false;
  bool? _isLoggedIn;

  final _onShutdown = <AsyncOrCallback>[];
  final _onLogin = <AsyncOrCallback>[];
  final _onLogout = <AsyncOrCallback>[];

  @protected
  void onShutdown(_AsyncCallback callback) {
    _onShutdown.add(callback);
  }

  void registerDisposer(FutureOr dispose()) {
    onShutdown(() async {
      await dispose();
    });
  }

  void removeDisposer(FutureOr dispose()) {}

  void _checkLoginStream() {
    if (_isLoggedIn == null) {
      _isLoggedIn = false;
      userStateStream.listen((state) async {
        final isLoggedIn = state.fbUser == null;
        if (isLoggedIn != _isLoggedIn) {
          this._isLoggedIn = isLoggedIn;
          final callbacks = isLoggedIn ? _onLogin : _onLogout;
          for (var callback in callbacks) {
            await callback();
          }
        }
      }).watch(this);
    }
  }

  @protected
  void onStartup(_AsyncCallback callback) {
    callback();
  }

  void registerLoginHooks(IAuthState authState) {
    // noop
  }

  @override
  bool isShuttingDown() {
    return _isShuttingDown;
  }

  @override
  Future doShutdown() async {}

  @override
  R? exec<R>(R block()) {
    if (isShuttingDown()) {
      log.severe("Trying to invoke function while shutting down", null,
          StackTrace.current);
      return null;
    } else {
      return block();
    }
  }

  @override
  void onLogout(AsyncOrCallback onLogout) {
    _onLogout.add(onLogout);
    _checkLoginStream();
  }

  @override
  void onLogin(AsyncOrCallback onLogin) {
    _onLogin.add(onLogin);
    _checkLoginStream();
  }

  @override
  Future dispose() async {
    if (!_isShuttingDown) {
      log.info("  - ${log.name} is shutting down now");
      await doShutdown();
      for (final shutdown in _onShutdown) {
        await shutdown();
      }
    } else {
      log.warning(
          "  - ${log.name} was already shutting down and we tried to shutdown again");
    }
  }
}

typedef LifecycleCallback<T> = FutureOr<T> Function();

extension LifecycleAwareBaseExt on LifecycleAwareBase {
  void onDestroy(String name, LifecycleCallback destroy, {Duration? wait}) {
    // if (_onDestroy.containsKey(name)) {
    //   throw "Initializer $name already exists for $runtimeType";
    // }
    if (wait != null) {
      onShutdown(() async {
        // Don't return this value because we dont' want to block startup
        Future.delayed(wait, destroy);
      });
    } else {
      onShutdown(() async => destroy);
    }
  }

  void autoTimer(String name, LifecycleCallback<Timer> generate) {
    onStartup(() async {
      final timer = await generate();

      onDestroy(name, () async {
        timer.cancel();
      });
    });
  }

  Future autoSubscribe(
      String name, LifecycleCallback<StreamSubscription> generate) async {
    onStartup(() async {
      final subscribe = await generate();

      onDestroy(name, () async {
        await subscribe.cancel();
      });
    });
  }

  Future autoStream<T>(LifecycleCallback<Stream<T>> stream,
      {bool cancelOnError = false}) async {
    onStartup(() async {
      final subscribe = (await stream()).listen((_) {}, cancelOnError: false);

      onShutdown(() async {
        await subscribe.cancel();
      });
    });
  }
}

extension StreamSubscriptionDisposingExt on StreamSubscription {
  void watch(HasDisposers disp) {
    disp.registerDisposer(this.cancel);
  }
}
