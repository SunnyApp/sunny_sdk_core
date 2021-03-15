import 'dart:async';

import 'package:flutter/widgets.dart';

typedef InstInitFn<T> = T Function(BuildContext context);
typedef InstDispose<T> = FutureOr Function(T t);

typedef ShouldNotify<T> = bool Function(T a, T b);

bool _never<T>(T a, T b) => false;

bool _notEquals<T>(T a, T b) => a != b;

/// Class used for defining container instances
class Inst<T> {
  final Type? t;
  final T? instance;
  final InstInitFn<T>? factory;
  final InstDispose<T>? dispose;
  final ShouldNotify<T>? shouldUpdate;
  final bool skipIfRegistered;

  Inst.instance(this.instance,
      {ShouldNotify<T>? shouldNotify, this.skipIfRegistered = true})
      : assert(instance != null),
        factory = null,
        this.shouldUpdate = shouldNotify ?? _notEquals,
        dispose = null,
        t = T;

  Inst._(
      {this.instance,
      this.t,
      this.dispose,
      this.factory,
      this.shouldUpdate,
      required this.skipIfRegistered});

  Inst.constant(this.instance, {this.skipIfRegistered = true})
      : assert(instance != null),
        factory = null,
        shouldUpdate = _never,
        dispose = null,
        t = T;

  Inst.factory(this.factory, {this.dispose, this.skipIfRegistered = true})
      : instance = null,
        shouldUpdate = _notEquals,
        t = T;

  bool get isInstance => instance != null;

  bool get isFactory => factory != null;

  R typed<R>(R passed<X>(Inst<X> inst)) {
    return passed<T>(this);
  }
}
