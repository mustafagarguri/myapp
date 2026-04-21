import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

class LocationSyncService {
  static Future<String?> captureAndSendCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'خدمة الموقع غير مفعلة.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return 'تم رفض إذن الموقع. يمكنك تفعيله من الإعدادات.';
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      await ApiService.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return null;
    } catch (_) {
      return 'تعذر تحديث الموقع حالياً.';
    }
  }
}
