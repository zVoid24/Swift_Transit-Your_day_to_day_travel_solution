import 'package:geolocator/geolocator.dart';
import 'package:swifttransit_bus/models/route_models.dart';

class LocationService {
  Stream<LatLng> positionStream() async* {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    await for (final position in Geolocator.getPositionStream()) {
      yield LatLng(latitude: position.latitude, longitude: position.longitude);
    }
  }

  Future<LatLng> currentPosition() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(latitude: position.latitude, longitude: position.longitude);
  }
}
