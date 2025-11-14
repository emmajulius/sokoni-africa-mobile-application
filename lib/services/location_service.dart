import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String? _currentAddress;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    try {
      // Request permission via geolocator first to keep the two APIs in sync
      final geolocatorPermission = await Geolocator.requestPermission();

      // Check the result
      if (geolocatorPermission == LocationPermission.deniedForever) {
        return LocationPermission.deniedForever;
      }

      // If permission is granted (whileInUse or always), return it
      if (geolocatorPermission == LocationPermission.whileInUse || 
          geolocatorPermission == LocationPermission.always) {
        return geolocatorPermission;
      }

      // If denied, check if we can request via permission_handler
      if (geolocatorPermission == LocationPermission.denied) {
        try {
          final permissionHandlerStatus = await Permission.location.request();
          if (permissionHandlerStatus.isGranted) {
            // Re-check with geolocator to get the actual permission type
            return await Geolocator.checkPermission();
          }

          if (permissionHandlerStatus.isPermanentlyDenied) {
            return LocationPermission.deniedForever;
          }

          return LocationPermission.denied;
        } catch (e) {
          // If permission_handler fails, return the geolocator result
          print('Error requesting permission via permission_handler: $e');
          return geolocatorPermission;
        }
      }

      return geolocatorPermission;
    } catch (e) {
      print('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        await Geolocator.openLocationSettings();
        return null;
      }

      // Check permission
      LocationPermission permission = await checkPermission();
      
      // If permission is permanently denied, open settings immediately
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        // Open app settings to allow user to grant permission
        await openAppSettings();
        return null;
      }
      
      // If permission is denied (but not permanently), request it
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
      }
      
      // Check the permission status after request
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        await openAppSettings();
        return null;
      }

      // Permission should be whileInUse or always at this point (both are valid on iOS and Android)
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        print('Location permission not granted: $permission');
        return null;
      }

      // If we get here, permissions are granted. Try getting position with increasing leniency.
      Position? position;
      Exception? lastError;

      final attempts = <LocationAccuracy>[
        LocationAccuracy.best,
        LocationAccuracy.high,
        LocationAccuracy.medium,
        LocationAccuracy.low,
      ];

      for (final accuracy in attempts) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: const Duration(seconds: 12),
          );
          break;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
        }
      }

      if (position == null && lastError != null) {
        print('Error getting current location: $lastError');
        return null;
      }

      // Get current position
      _currentPosition = position;
      if (_currentPosition != null) {
        // Cache reverse-geocoded address for convenience. Ignore failures silently.
        try {
          final placemarks = await placemarkFromCoordinates(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            _currentAddress = [
              place.street,
              place.locality,
              place.administrativeArea,
              place.country,
            ]
                .whereType<String>()
                .map((segment) => segment.trim())
                .where((segment) => segment.isNotEmpty)
                .join(', ');
          }
        } catch (_) {
          // ignore reverse geocode errors
        }
      }

      return _currentPosition;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = '${place.street}, ${place.locality}, ${place.country}';
        return _currentAddress;
      }
      return null;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Get current position (cached)
  Position? get currentPosition => _currentPosition;

  /// Get current address (cached)
  String? get currentAddress => _currentAddress;

  /// Clear cached location
  void clearLocation() {
    _currentPosition = null;
    _currentAddress = null;
  }
}
