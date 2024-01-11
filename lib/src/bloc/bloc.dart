import 'package:firebase_core/firebase_core.dart';

import './services/device_info_service.dart';
import './services/qr_service.dart';
import './services/permissions_service.dart';


class Bloc {
    DeviceInfoService device;
    PermissionsService permissions;
    QrService qr;
    FirebaseApp firebaseApp;

    Bloc(FirebaseApp firebaseApp) {
        firebaseApp = firebaseApp;
        device = DeviceInfoService();
        permissions = PermissionsService();
        qr = QrService(permissions);
    }

    dispose() {
        permissions.dispose();
        qr.dispose();
    }
}
