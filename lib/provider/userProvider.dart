import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier, DiagnosticableTreeMixin {
  String _deviceID = '';
  int _locationID = 0;
  String _locationCode = '';
  String _location = '';
  String _latitude = '';
  String _longitude = '';
  int _isAdmin = 0;
  void setDevice(String deviceID) {
    _deviceID = deviceID;
  }

  void setLocation(
      int locationID, String locationCode, String location, int isAdmin) {
    _locationID = locationID;
    _locationCode = locationCode;
    _location = location;
    _isAdmin = isAdmin;
  }

  void setLatLong(String lat, String long) {
    _latitude = lat;
    _longitude = long;
  }

  Map<String, dynamic> getUserDetails() {
    return {
      'deviceID': _deviceID,
      'locationID': _locationID,
      'locationCode': _locationCode,
      'location': _location,
      'latitude': _latitude,
      'longitude': _longitude,
      'isAdmin': _isAdmin
    };
  }
}
