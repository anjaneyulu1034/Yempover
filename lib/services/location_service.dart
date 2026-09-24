// lib/services/location_service.dart
//
// Google Maps/Places/GPS integration was removed app-wide (billed API key,
// no longer wanted). Every caller that used to fetch the device's real GPS
// position now gets this fixed Hyderabad default instead — same public
// shape (address string + lat/lng), just no permission prompts, no device
// sensors, no Google API calls.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String defaultAddress = 'Hyderabad, Telangana, India';
  static const double defaultLatitude = 17.3850;
  static const double defaultLongitude = 78.4867;

  Future<String?> getCurrentAddress() async => defaultAddress;

  Future<({double latitude, double longitude})> getCurrentLatLng() async =>
      (latitude: defaultLatitude, longitude: defaultLongitude);
}
