//   final double lng;
//
//   factory GeoLocation.fromJson(json) {
//     if (json is GeoLocation) return json;
//     if (json is! Map<String, dynamic>) {
//       return illegalState("Must be map data");
//     }
//     return GeoLocation(
//       lat: json["lat"] as double,
//       lng: json["lng"] as double,
//     );
//   }
//
//   GeoLocation({this.lat, this.lng});
//
//   toJson() => {
//     "lat": lat,
//     "lng": lng,
//   };
// }
//
// class Dimensions {
//   final double height;
//   final double width;
//
//   factory Dimensions.fromJson(json) {
//     if (json is Dimensions) return json;
//     if (json is! Map<String, dynamic>) {
//       return illegalState("Must be map data");
//     }
//     return Dimensions(
//       height: json["height"] as double,
//       width: json["width"] as double,
//     );
//   }
//
//   Dimensions({this.height, this.width});
//
//   toJson() => {
//     "height": height,
//     "width": width,
//   };
// }
