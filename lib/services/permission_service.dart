import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAppPermissions() async {
    // permission_handler doesn't support web and will throw UnsupportedError
    if (kIsWeb) return;

    // Request multiple permissions at once.
    // If they are already granted, this will just return quickly.
    await [
      Permission.camera,
      Permission.contacts,
      Permission.microphone,
      Permission.location,
    ].request();
  }
}
