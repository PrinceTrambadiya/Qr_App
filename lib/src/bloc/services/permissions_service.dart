import 'package:rxdart/rxdart.dart';

import '../platform_channels/permissions_channel.dart';

class PermissionsService {
  BehaviorSubject<bool> cameraPermitted = BehaviorSubject<bool>();
  BehaviorSubject<bool> allRequested = BehaviorSubject<bool>();
  Stream<bool> get allPermitted => cameraPermitted.map((camera) {
        if (camera) {
          allRequested.sink.add(true);
          return true;
        } else {
          return false;
        }
      });

  PermissionsService() {
    cameraPermitted.sink.add(false);
    allRequested.sink.add(false);
    PermissionsChannel.checkCamera().then((result) {
      // print('checked camera = $result');
      cameraPermitted.sink.add(result);
    });
  }

  /// returns `false` if the user denies camera permission or there was an error
  Future<bool> requestCameraPermission() async {
    if (cameraPermitted.value) return Future.value(true);
    try {
      final permitted = await PermissionsChannel.requestCamera();
      if (!permitted) throw 'user denied camera permission!';
      cameraPermitted.sink.add(true);
      return true;
    } catch (err) {
      // print('[PermissionsService][requestCameraPermission] ERROR = $err');
      cameraPermitted.sink.add(false);
      return false;
    }
  }

  dispose() {
    cameraPermitted.close();
    allRequested.close();
  }
}
