import 'package:sunny_sdk_core/mverse.dart';

class DeleteResponse extends MModel {
  final bool deleted;

  DeleteResponse.of({bool deleted}) : this({"deleted": deleted});

  DeleteResponse(Map<String, dynamic> values)
      : deleted = values["deleted"] == true,
        super(values);

  factory DeleteResponse.fromJson(json) {
    return DeleteResponse(json as Map<String, dynamic>);
  }

  @override
  Map<String, dynamic> toMap() {
    return wrapped ?? {};
  }
}
