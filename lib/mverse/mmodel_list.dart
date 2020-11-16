import 'dart:core';

abstract class MModelList<M> {
  Iterable<M> get data;

  int get count;
}

class DefaultMModelList<M> implements MModelList<M> {
  final List<M> data;
  final int count;

  DefaultMModelList(this.data, this.count);
  DefaultMModelList.ofList(this.data) : count = data.length;
}
