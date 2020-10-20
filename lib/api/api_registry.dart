import 'dart:async';

import 'package:meta_forms/mverse.dart';
import 'package:sunny_dart/helpers/functions.dart';
import 'package:sunny_dart/helpers/logging_mixin.dart';
import 'package:sunny_sdk_core/api/repository.dart';
import 'package:sunny_sdk_core/api/sunny_api.dart';
import 'package:sunny_sdk_core/auth/auth_user_profile.dart';
import 'package:sunny_sdk_core/model/change_result.dart';
import 'package:sunny_sdk_core/model/delete_response.dart';
import 'package:sunny_sdk_core/services/lifecycle_aware.dart';
import 'package:sunny_sdk_core/services/sunny.dart';

ApiRegistry get apiRegistry => Sunny.get();

abstract class ApiRegistry {
  void register(Repository repo);

  Repository get(MSchemaRef ref);

  factory ApiRegistry(Stream<AuthUserProfile> userStateChanges) =>
      _ApiRegistry(userStateChanges);

  factory ApiRegistry.noop() => const _NoopApiRegistry();

  afterCreate<T>(MKey newKey, T result);

  afterDelete<T>(MKey deletedKey, DeleteResponse result);

  afterUpdate<T>(MKey updatedKey, T updateSource, ChangeResult result);

  Stream<ApiSignal> get stream;
}

/// Used in isolates
class _NoopApiRegistry implements ApiRegistry {
  @override
  void register(Repository repo) {}

  @override
  SunnyApi get(MSchemaRef ref) {
    return notImplemented();
  }

  const _NoopApiRegistry();

  @override
  afterCreate<T>(MKey newKey, T result) {}

  @override
  afterUpdate<T>(MKey updatedKey, T updateSource, ChangeResult result) {}

  @override
  afterDelete<T>(MKey deletedKey, DeleteResponse result) {}

  @override
  Stream<ApiSignal> get stream => Stream.empty();
}

abstract class ApiSignal<T> {}

class ApiCreateSignal<T> implements ApiSignal<T> {
  final MKey newKey;
  final T newEntity;

  ApiCreateSignal(this.newKey, this.newEntity);
}

class ApiDeleteSignal<T> implements ApiSignal<T> {
  final MKey deletedKey;

  ApiDeleteSignal(this.deletedKey);
}

class ApiUpdateSignal<T> implements ApiSignal<T> {
  final MKey updatedKey;
  final T updatedEntity;
  final ChangeResult result;

  ApiUpdateSignal(this.updatedKey, this.updatedEntity, this.result);
}

class _ApiRegistry
    with LoggingMixin, LifecycleAwareMixin
    implements ApiRegistry, LifecycleAwareBase {
  final Map<MSchemaRef, Repository> _apis = {};
  final StreamController<ApiSignal> _signalStream =
      StreamController.broadcast();

  Stream<ApiSignal> get stream => _signalStream.stream;

  @override
  final Stream<AuthUserProfile> userStateStream;

  _ApiRegistry(this.userStateStream) {
    onShutdown(() => _signalStream.close());
  }

  @override
  void register(Repository repo) => _apis[repo.mtype] = repo;

  Repository get(MSchemaRef ref) =>
      _apis[ref] ?? nullPointer("No repository registered for ${ref.baseCode}");

  @override
  afterCreate<T>(MKey newKey, T result) {
    if (_signalStream.hasListener) {
      _signalStream.add(ApiCreateSignal(newKey, result));
    }
  }

  @override
  afterDelete<T>(MKey deletedKey, DeleteResponse result) {
    if (result.deleted == true && _signalStream.hasListener) {
      _signalStream.add(ApiDeleteSignal(deletedKey));
    }
  }

  @override
  afterUpdate<T>(MKey updatedEntity, T updateSource, ChangeResult result) {
    if (_signalStream.hasListener)
      _signalStream.add(ApiUpdateSignal(updatedEntity, updateSource, result));
  }
}

extension ApiSignalStream on Stream<ApiSignal> {
  Stream<ApiSignal> whereTypeIs(MSchemaRef type) {
    if (this == null) return Stream.empty();
    return this.where((signal) {
      if (signal is ApiUpdateSignal) {
        return signal.updatedKey.mtype == type;
      } else if (signal is ApiDeleteSignal) {
        return signal.deletedKey.mtype == type;
      } else if (signal is ApiCreateSignal) {
        return signal.newKey.mtype == type;
      } else {
        return false;
      }
    });
  }

  Stream<ApiSignal<T>> whereType<T>() {
    if (this == null) return Stream.empty();
    return this.where((signal) {
      return signal is ApiSignal<T>;
    }).cast();
  }
}

extension RepositoryExtensions<X extends Entity> on Repository<X> {
  Future<X> save(X toSave) async {
    assert(toSave != null);
    if (toSave.mkey?.mxid != null) {
      await this.update(this.keyToId(toSave.mkey), toSave);
      return await this.load(keyToId(toSave.mkey));
    } else {
      return await this.create(toSave);
    }
  }
}
