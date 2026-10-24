import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents the status of location permission and device GPS availability.
enum LocationStatus {
  notRequested,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Service providing device location, permission handling, distance computation,
/// and location settings navigation.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String _prefKeyRequested = 'craveguard_location_permission_requested';
  bool? _cachedHasRequested;

  Future<bool> _hasRequestedPermission() async {
    if (_cachedHasRequested != null) return _cachedHasRequested!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedHasRequested = prefs.getBool(_prefKeyRequested) ?? false;
      return _cachedHasRequested!;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setRequestedPermission(bool requested) async {
    _cachedHasRequested = requested;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyRequested, requested);
    } catch (_) {}
  }

  /// Checks whether GPS service is enabled and permission status.
  Future<LocationStatus> checkPermissionStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationStatus.serviceDisabled;
      }

      final permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationStatus.granted;
        case LocationPermission.deniedForever:
          return LocationStatus.deniedForever;
        case LocationPermission.denied:
          final requested = await _hasRequestedPermission();
          return requested ? LocationStatus.denied : LocationStatus.notRequested;
        case LocationPermission.unableToDetermine:
          return LocationStatus.notRequested;
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return LocationStatus.denied;
    }
  }

  /// Requests foreground location permission from the operating system.
  Future<LocationStatus> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationStatus.serviceDisabled;
      }

      await _setRequestedPermission(true);
      final permission = await Geolocator.requestPermission();

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationStatus.granted;
        case LocationPermission.deniedForever:
          return LocationStatus.deniedForever;
        case LocationPermission.denied:
          return LocationStatus.denied;
        case LocationPermission.unableToDetermine:
          return LocationStatus.denied;
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return LocationStatus.denied;
    }
  }

  /// Returns current position if permission is granted, otherwise null.
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('getCurrentPosition failed, trying last known position: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Calculates geodesic distance in meters between two lat/lng coordinates.
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (_) {
      return 0.0;
    }
  }

  /// Opens platform location settings screen.
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Failed to open location settings: $e');
      return false;
    }
  }

  /// Opens platform application settings screen.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Failed to open app settings: $e');
      return false;
    }
  }
}
