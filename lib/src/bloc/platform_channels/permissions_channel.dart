import 'package:flutter/services.dart';

const METHOD_CHECK_CAMERA = 'checkCamera';
const METHOD_REQUEST_CAMERA = 'requestCamera';

class PermissionsChannel {
    static const MethodChannel _permissions = const MethodChannel('io.kernellabs.pitch_conferencing/permissions');

    static Future<bool> checkCamera() async {
        try {
            final bool permitted = await _permissions.invokeMethod<bool>(METHOD_CHECK_CAMERA);
            return permitted;
        } catch (err) {
            // print('[PermissionsChannel][checkCamera] ERROR = $err');
            return false;
        }
    }

    /// returns false if the user denies permission
    static Future<bool> requestCamera() async {
        try {
            final bool permitted = await _permissions.invokeMethod<bool>(METHOD_REQUEST_CAMERA);
            if (permitted) {
                // print('[PermissionsChannel][requestCamera] user has permitted camera access');
            } else {
                // print('[PermissionsChannel][requestCamera] user denied camera access');
            }
            return permitted;
        } catch (err) {
            // print('[PermissionsChannel][requestCamera] ERROR = $err');
            return false;
        }
    }
}