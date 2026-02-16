// lib/services/location_service.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Open app settings
      await openAppSettings();
      return false;
    }

    return true;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('🔴 LocationService: Location services are disabled');
        return null;
      }

      bool permissionGranted = await requestLocationPermission();
      if (!permissionGranted) {
        debugPrint('🔴 LocationService: Location permission denied');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint(
        '📍 LocationService: Current position: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('🔴 LocationService: Error getting location: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<String?> getAddressFromLatLng(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        //localeIdentifier: 'en_US',
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Format address
        List<String> addressParts = [];

        if (place.street?.isNotEmpty ?? false) {
          addressParts.add(place.street!);
        }
        if (place.subLocality?.isNotEmpty ?? false) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality?.isNotEmpty ?? false) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea?.isNotEmpty ?? false) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country?.isNotEmpty ?? false) {
          addressParts.add(place.country!);
        }
        if (place.postalCode?.isNotEmpty ?? false) {
          addressParts.add(place.postalCode!);
        }

        String address = addressParts.join(', ');
        debugPrint('📍 LocationService: Address: $address');
        return address;
      }

      return null;
    } catch (e) {
      debugPrint('🔴 LocationService: Error getting address: $e');
      return null;
    }
  }

  // Get current address
  Future<String?> getCurrentAddress() async {
    try {
      Position? position = await getCurrentLocation();
      if (position == null) {
        return null;
      }

      String? address = await getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      return address;
    } catch (e) {
      debugPrint('🔴 LocationService: Error getting current address: $e');
      return null;
    }
  }

  // Show location permission dialog
  Future<void> showLocationPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Yempover needs access to your location to set your current location for posts. '
            'Please enable location access in settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
}
