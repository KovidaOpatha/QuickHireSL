import 'package:geolocator/geolocator.dart';

class LocationService {
  // List of standardized locations
  static final List<String> standardLocations = [
    'Dehiwala',
    'Mount Lavinia',
    'Nugegoda',
    'Maharagama',
    'Boralesgamuwa',
    'Battaramulla',
    'Kaduwela',
    'Athurugiriya',
    'Malabe',
    'Homagama',
    'Pannipitiya',
    'Piliyandala',
    'Ratmalana',
    'Wattala',
    'Kelaniya',
    'Ja-Ela',
    'Negombo',
    'Panadura',
    'Moratuwa',
    'Kadawatha',
    'Gampaha',
  ];

  // Get the list of available locations
  List<String> getAvailableLocations() {
    return standardLocations;
  }

  // Validate if a location is in the standardized list
  bool isValidLocation(String location) {
    return standardLocations.contains(location);
  }
}