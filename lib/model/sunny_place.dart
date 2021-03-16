import 'package:sunny_dart/helpers/lists.dart';
import 'package:sunny_sdk_core/mverse/m_model.dart';

Iterable<String>? addressToString(SunnyPlace? address) {
  if (address == null) {
    return null;
  }

  final statePostal =
      Lists.compactEmpty([address.region, address.postalCode]).join(", ");
  final regionLine =
      Lists.compactEmpty([address.locality, statePostal]).join(" ");
  return Lists.compactEmpty([
    address.description,
    address.streetLineOne,
    address.streetLineTwo,
    address.streetLineThree,
    regionLine,
  ]);
}

/// Represents a physical location.  Represented by a few different generated models.  See [Location]
/// and [ContactAddress]
abstract class SunnyPlace implements MModel {
  String? get name;

  String? get googlePlaceId;

  String? get description;

  String? get type;

  String? get streetLineOne;

  String? get streetLineTwo;

  String? get streetLineThree;

  String? get locality;

  String? get region;

  String? get postalCode;

  String? get countryCode;

  set googlePlaceId(String? googlePlaceId);

  set name(String? name);

  set description(String? description);

  set type(String? type);

  set streetLineOne(String? streetLineOne);

  set streetLineTwo(String? streetLineTwo);

  set streetLineThree(String? streetLineThree);

  set locality(String? locality);

  set region(String? region);

  set postalCode(String? postalCode);

  set countryCode(String? countryCode);

// PlaceDetails get placeDetails;
// set placeDetails(PlaceDetails placeDetails);
}
