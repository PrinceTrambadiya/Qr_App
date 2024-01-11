import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:qr_tester/src/bloc/QrResultModel.dart';

import '../bloc/provider.dart';
import '../widgets/qr_camera.dart';

class HomeScreen extends StatelessWidget {
  build(BuildContext context) {
    final bloc = Provider.of(context);
    print('~~~ Building HomeScreen ~~~');
    return StreamBuilder(
        stream: bloc.permissions.allRequested,
        builder: (context, snapshot) {
          final allRequested = snapshot.hasData && snapshot.data;
          if (!allRequested) {
            print('~~~ Building Request Permissions ~~~');
            return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.white,
                ),
                body: Column(
                  children: [
                    Expanded(flex: 0, child: SizedBox(height: 16)),
                    Expanded(flex: 2, child: Text('Request Permissions')),
                    Expanded(flex: 2, child: SizedBox()),
                    Expanded(flex: 5, child: SizedBox()),
                    Expanded(flex: 1, child: _okayButton(context, bloc)),
                    Expanded(flex: 0, child: SizedBox(height: 32)),
                  ],
                ));
          } else {
            print('~~~ Building Qr Camera Scaffold ~~~');
            return StreamBuilder(
                stream: bloc.qr.qrResult,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Scaffold(
                        body: Stack(children: [
                      _qrCamera(bloc),
                    ]));
                  }
                  if (snapshot.hasData) {
                    if (snapshot.data == true) {
                      return Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    } else {
                      QrResultModel qrResultModel = snapshot.data;
                      return Scaffold(
                        body: Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("CounterFeit = " +
                                  qrResultModel.counterfeit.toString()),
                              Text("Match = " + qrResultModel.match),
                              Text("Base Percentage = " +
                                  qrResultModel.base_percentage),
                              _okayButton(context, bloc)
                            ],
                          ),
                        ),
                      );
                    }
                  }
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                });
          }
        });
  }

  Widget _okayButton(BuildContext context, Bloc bloc) {
    return Row(children: [
      Expanded(flex: 1, child: SizedBox()),
      Expanded(
          flex: 8,
          child: RaisedButton(
              child: Text('Okay'),
              onPressed: () async {
                Location location = new Location();
                final cameraPermitted =
                    await bloc.permissions.requestCameraPermission();
                bool isLocation = await getLocation();
                LocationData _locationData = await location.getLocation();
                cameraPermitted
                    ? print('user granted camera permission')
                    : print('user denied camera permission');
                isLocation
                    ? print('user granted Location permission')
                    : print('user denied Location permission');
                if (cameraPermitted && isLocation) {
                  bloc.permissions.allRequested.sink.add(true);
                  bloc.qr.qrResult.sink.add(null);
                }
              })),
      Expanded(flex: 1, child: SizedBox()),
    ]);
  }

  Future<bool> getLocation() async {
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.granted) {
      return true;
    } else if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted == PermissionStatus.granted) {
        return true;
        // _serviceEnabled = await location.serviceEnabled();
        // if (!_serviceEnabled) {
        //   _serviceEnabled = await location.requestService();
        //   return _serviceEnabled;
        // }
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Widget _qrCamera(Bloc bloc) {
    return StreamBuilder(
        stream: bloc.permissions.cameraPermitted,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return SizedBox();
          final cameraPermitted = snapshot.data;
          if (cameraPermitted) {
            return StreamBuilder(
                stream: bloc.qr.cameraInitialized,
                builder: (context, AsyncSnapshot<bool> snapshot) {
                  if (!snapshot.hasData || !snapshot.data) {
                    return Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SizedBox());
                  }
                  return Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        child: QrCamera(onResult: (String result) {
                          print('[JoinCall] QrCamera result = $result');
                        }),
                      ));
                });
          } else {
            return Card(
                child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 16),
                  Flexible(
                      child: Text(
                          'Pitch needs camera access for joining calls via QR codes.'))
                ]),
                SizedBox(height: 16),
                RaisedButton(
                    child: Text('Okay'),
                    onPressed: () {
                      bloc.permissions.requestCameraPermission();
                    })
              ]),
            ));
          }
        });
  }
}
