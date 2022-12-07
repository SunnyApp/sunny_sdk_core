abstract class ContactInfoPart {
  String? get type;

  set type(String? type);

  /// Returns the value, whatever it is
  dynamic get infoValue;

  /// Sets the value, whatever it is
  set infoValue(dynamic infoValue);
}
