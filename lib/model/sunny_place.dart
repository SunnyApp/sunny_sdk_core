import 'package:sunny_dart/helpers/lists.dart';
import 'package:sunny_sdk_core/mverse/m_model.dart';

import 'geo_location.dart';

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
abstract class SunnyPlace {
  GeoLocation? get geo;
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

  set geo(GeoLocation? geo);
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

  void prune(Set<String> values);
// PlaceDetails get placeDetails;
// set placeDetails(PlaceDetails placeDetails);
}

extension SunnyPlaceHelperExt on SunnyPlace {
  bool get hasGeo => geo?.lat != null && geo?.lon != null;
}

class DefaultSunnyPlace implements SunnyPlace {
  GeoLocation? geo;
  String? name;

  String? googlePlaceId;

  String? description;

  String? type;

  String? streetLineOne;

  String? streetLineTwo;

  String? streetLineThree;

  String? locality;

  String? region;

  String? postalCode;

  String? countryCode;

  @override
  void prune(Set<String> values) {}
}
