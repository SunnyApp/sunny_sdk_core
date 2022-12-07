import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sunny_sdk_core/sunny_sdk_core.dart';

abstract class MutableRecordDataService<RType, KType, CType, UType> extends RecordDataService<RType, KType> {
  Future<RType> internalCreate(CType create);

  Future<RType> internalUpdate(KType id, UType update);

  Future<bool> internalDelete(KType id);

  FutureOr<RType?> applyUpdate(RType source, UType updates) => null;

  Future<RType> update(KType id, UType update) async {
    tryUpdateRecord(id, (input) async {
      if (input == null) return null;
      return applyUpdate(input, update);
    });

    final saved = await internalUpdate(id, update);
    updateRecord(id, (record) => SynchronousFuture(saved));
    return saved;
  }

  Future<RType> create(CType ctype) async {
    var newContact = await internalCreate(ctype);
    addToStream(newContact);
    return newContact;
  }

  Future<bool> delete(KType id) async {
    return await internalDelete(id);
  }
}
