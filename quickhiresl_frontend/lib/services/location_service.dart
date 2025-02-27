import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp?.toIso8601String(),
      };
    } catch (e) {
      print('Location Error: $e');
      return null;
    }
  }

  // Optional: Convert coordinates to readable address
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    // You might want to use Google Geocoding API or another service here
    // This is a placeholder implementation
    return 'Location: $latitude, $longitude';
  }
}