import 'dart:convert';
import 'dart:html';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as imglib;
import 'package:location/location.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_tester/src/bloc/QrResultModel.dart';
import 'package:rxdart/rxdart.dart';

import './permissions_service.dart';

class QrService {
  PermissionsService _permissionsService;

  final BarcodeDetector barcodeDetector = FirebaseVision.instance
      .barcodeDetector(
          BarcodeDetectorOptions(barcodeFormats: BarcodeFormat.qrCode));
  BehaviorSubject<CameraController> cameraController =
      BehaviorSubject<CameraController>();
  BehaviorSubject<dynamic> qrResult = BehaviorSubject<dynamic>();
  // BehaviorSubject<Image> qrResult = BehaviorSubject<Image>();

  bool _alreadyCheckingImage = false;
  bool _foundRoomId = false;
  Location location = new Location();

  QrService(PermissionsService permissionsService) {
    _permissionsService = permissionsService;
    cameraController.sink.add(null);
    _permissionsService.cameraPermitted.stream.distinct().listen((permitted) {
      // print('[QrService]: cameraPermitted doOnData = $permitted');
      final alreadyInit = cameraController.value != null &&
          cameraController.value.value != null &&
          cameraController.value.value.isInitialized;
      if (permitted && !alreadyInit) {
        // print('[QrService]: init camera controller');
        initCamera();
      }
    });
  }

  Stream<bool> get cameraInitialized => cameraController.map((controller) =>
      controller != null &&
      controller.value != null &&
      controller.value.isInitialized);

  Future<void> initCamera() async {
    // print('[QrService][initCamera]');
    try {
      final cameras = await availableCameras();
      if (cameras == null || cameras.first == null)
        throw 'no available cameras!';
      final newCameraController = CameraController(
        cameras.first,
        ResolutionPreset.ultraHigh,
        enableAudio: false,
      );
      return newCameraController
          .initialize()
          .then((_) => Future.delayed(Duration(milliseconds: 1000)))
          .then((_) {
        cameraController.sink.add(newCameraController);
      }).catchError((err) {
        // print(err);
      });
    } catch (err) {
      // print('[QrService][initCamera] ERROR = $err');
      throw err;
    }
  }

  Future<void> disposeCamera() async {
    // print('[QrService][disposeCamera]');
    _foundRoomId = false;
    _alreadyCheckingImage = false;
    try {
      await stopScanning();
      if (cameraController.value != null) {
        await cameraController.value.dispose();
        cameraController.sink.add(null);
      }
    } catch (err) {
      // print('[QrService][disposeCamera] ERROR = $err');
      throw err;
    }
  }

  /// expects joinCallContext to already been provided
  Future<void> startScanning() async {
    // print('[QrService][startScanning]');
    if (cameraController == null ||
        cameraController.value == null ||
        cameraController.value.value == null ||
        cameraController.value.value.hasError == true ||
        cameraController.value.value.isInitialized == false) {
      try {
        if (!_permissionsService.cameraPermitted.value) {
          throw '[QrService][startScanning] no camera access! cannot start scanning!';
        }
        print('''[QrService][startScanning] restarting camera reason:
                    cameraController == null ? $cameraController
                    || cameraController.value == null ? ${cameraController.value}
                    || cameraController.value.value == null ? ${cameraController.value.value}
                    || cameraCont roller.value.value.hasError == true ? ${cameraController.value.value.hasError}
                    || cameraController.value.value.isInitialized == false ? ${cameraController.value.value.isInitialized}
                ''');
        await _restartCamera();
      } catch (err) {
        print('[QrService][startScanning] _restartCamera ERROR = $err');
      }
    }

    _foundRoomId = false;
    if (cameraController.value == null ||
        cameraController.value.value.isStreamingImages == true) {
      print(
          '[QrService][startScanning] cameraController.value = ${cameraController.value}');
      print(
          '[QrService][startScanning] cameraController.value.value.isStreamingImages = ${cameraController.value.value.isStreamingImages}');
      return Future.value();
    }

    try {
      // set a reference to the context so we can navigate to the in_call screen
      print('[QrService][startScanning] startImageStream');
      await cameraController.value.startImageStream(_processImage);
    } catch (err) {
      print('[QrService][startScanning] startImageStream ERROR = $err');
      return _restartCamera();
    }
  }

  Future<void> _restartCamera() async {
    try {
      await disposeCamera();
      await initCamera();
    } catch (err) {
      print('[QrService][_restartCamera] ERROR = $err');
    }
  }

  _processImage(CameraImage image) async {
    if (!_alreadyCheckingImage && !_foundRoomId) {
      _alreadyCheckingImage = true;
      try {
        final barcodes = await barcodeDetector.detectInImage(
          FirebaseVisionImage.fromBytes(
            _concatenatePlanes(image.planes),
            FirebaseVisionImageMetadata(
              rawFormat: image.format.raw,
              size: Size(image.width.toDouble(), image.height.toDouble()),
              rotation: ImageRotation.rotation0,
              planeData: image.planes
                  .map(
                    (plane) => FirebaseVisionImagePlaneMetadata(
                      bytesPerRow: plane.bytesPerRow,
                      height: plane.height,
                      width: plane.width,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        if (barcodes != null && barcodes.length > 0) {
          try {
            qrResult.sink.add(true);
            // QrResultModel qrResultModel = await convertImageToPng(image);

            final barcode = barcodes.first.boundingBox;
            var points = barcodes.first.cornerPoints;
            print(barcode);
            var a = Rect.fromLTRB(311.4, 265.9, 341.4, 295.9);
            var o = a.overlaps(barcode);
            var b = a.intersect(barcode);
            final bool doesContain = b == barcode;
            print(doesContain);
            if (a.contains(barcode.center)) {
              print(
                  "---------------------------------------------------------------------");
            }
            qrResult.sink.add(QrResultModel());
            _foundRoomId = true;
          } catch (err, stack) {
            print('$err\n$stack');
          }
        }
      } catch (err, stack) {
        debugPrint('$err, $stack');
      }
      _alreadyCheckingImage = false;
    }
  }

  Future<void> stopScanning() {
    print('[QrService][stopScanning]');
    if (cameraController.value == null ||
        !cameraController.value.value.isStreamingImages) {
      return Future.value();
    }
    return cameraController.value.stopImageStream();
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
  }

  dispose() {
    stopScanning().then((_) {
      cameraController.value.dispose();
      qrResult.close();
    });
  }

  Future<dynamic> convertImageToPng(CameraImage image) async {
    Uint8List bytes;
    QrResultModel response;
    try {
      imglib.Image img;
      if (image.format.group == ImageFormatGroup.yuv420) {
        // bytes = await convertYUV420toImageColor(image);
        response = await convertYUV420toImageColor(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        img = _convertBGRA8888(image);
        imglib.PngEncoder pngEncoder = new imglib.PngEncoder();
        bytes = pngEncoder.encodeImage(img);
      }

      // return bytes;
      return response;
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
  }

  imglib.Image _convertBGRA8888(CameraImage image) {
    return imglib.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: imglib.Format.bgra,
    );
  }

  Future<dynamic> convertYUV420toImageColor(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel;

      print("uvRowStride: " + uvRowStride.toString());
      print("uvPixelStride: " + uvPixelStride.toString());
      var img = imglib.Image(width, height); // Create Image buffer

      // Fill image buffer with plane[0] from YUV420_888
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex =
              uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          img.data[index] = (0xFF << 24) | (b << 16) | (g << 8) | r;
        }
      }

      imglib.PngEncoder pngEncoder = new imglib.PngEncoder(level: 0, filter: 0);
      Uint8List png = pngEncoder.encodeImage(img);

      final originalImage = imglib.decodeImage(png);
      final height1 = originalImage.height;
      final width1 = originalImage.width;
      imglib.Image fixedImage;

      if (height1 < width1) {
        fixedImage = imglib.copyRotate(originalImage, 90);
      }
      final path =
          join((await getTemporaryDirectory()).path, "${DateTime.now()}.jpg");
      File(path).writeAsBytesSync(imglib.encodeJpg(fixedImage));
      var response =
          await uploadImage("http://13.59.194.105/api/v1/uploadImage/", path);
      print(response.toString());
      // return imglib.encodeJpg(fixedImage);
      QrResultModel qrResultModel = new QrResultModel.fromJson(response);
      // return response.toString();
      return qrResultModel;
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
  }

  Future<dynamic> printIps() async {
    var address;
    for (var interface in await NetworkInterface.list()) {
      print('== Interface: ${interface.name} ==');
      for (var addr in interface.addresses) {
        address = addr.address;
        // print(
        //     '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
      }
    }
    return address;
  }

  Future<dynamic> uploadImage(String url, dynamic data,
      {Map<String, String> headers}) async {
    var uri = Uri.parse(url);
    LocationData locationData = await location.getLocation();
    String address = await printIps();
    var data1 = {
      "ipaddress": address,
      "latitude": locationData.latitude,
      "longitude": locationData.longitude
    };
    debugPrint('Upload Image = $url');
    if (headers == null) {
      headers = new Map<String, String>();
    }
    headers.addAll({"Accept": "*/*", "Content-Type": "multipart/form-data"});
    var request = new http.MultipartRequest('POST', uri);
    data1.forEach((k, v) {
      request.fields[k] = v.toString();
    });
    request.fields["sampleFile"] = data;
    var multiPartFile = await http.MultipartFile.fromPath("file", data);

    request.headers
        .addAll({"Accept": "*/*", "Content-Type": "multipart/form-data"});
    request.files.add(multiPartFile);
    var response = await request.send();

    if (response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 404 ||
        response.statusCode == 500) {
      debugPrint('==== FAILED ====');
      debugPrint('body: ${response.toString()}');
      // throw _parseError(response.statusCode, response.toString());
    }
    var jsonResponse = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      debugPrint("Image Uploaded");
      debugPrint("Response " + jsonResponse);
      return json.decode(jsonResponse);
    } else {
      debugPrint("Upload Failed");
    }

    throw ('An error occurred');
  }
}
