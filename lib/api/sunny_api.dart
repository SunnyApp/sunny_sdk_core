import 'package:meta_forms/mverse.dart';
import 'package:sunny_dart/helpers/functions.dart';
import 'package:sunny_sdk_core/api/api_registry.dart';
import 'package:sunny_sdk_core/api/repository.dart';

typedef MModelInstantiator<M extends Entity> = M Function([dynamic json]);

abstract class SunnyApi<M extends Entity> extends Repository<M> {
  final ApiRegistry apis;
  SunnyApi(this.apis, this._factoryMethod) {
    apis.register(this);
  }

  MSchemaRef get mtype => illegalState("Not implemented");
  final MModelInstantiator<M> _factoryMethod;

  @override
  M instantiate([dynamic json]) =>
      json != null ? _factoryMethod(json) : _factoryMethod();

  @override
  M clone(M source) => source.clone() as M;

  @override
  void takeFrom(M source, M target) {
    target.takeFrom(source);
  }

  @override
  String keyToId(MKey key) => key?.recordKey?.value;
}
