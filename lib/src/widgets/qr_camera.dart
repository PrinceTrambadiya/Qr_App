import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../bloc/provider.dart';

class QrCamera extends StatefulWidget {
  final Function onResult;

  QrCamera({@required this.onResult});

  _QrCameraState createState() => _QrCameraState();
}

// based on google's flutter camera example
// https://flutter.dev/docs/cookbook/plugins/picture-using-camera
class _QrCameraState extends State<QrCamera> with WidgetsBindingObserver {
  Bloc bloc;
  GlobalKey _globalKey = new GlobalKey();
  CameraController controller;

  Future getCameras() async {
    final cameras = await availableCameras();
    controller = new CameraController(cameras.first, ResolutionPreset.ultraHigh,
        enableAudio: false);
    setState(() {});
  }

  Widget build(BuildContext context) {
    bloc = Provider.of(context);
    print('~~~ Building _QrCameraState ~~~');
    // bloc.qr.startScanning();
    Future.delayed(Duration(milliseconds: 500))
        .then((_) => bloc.qr.startScanning());
    return StreamBuilder(
        stream: bloc.qr.cameraController,
        builder: (context, AsyncSnapshot<CameraController> snapshot) {
          if (!snapshot.hasData || !snapshot.data.value.isInitialized) {
            return SizedBox();
          }
          final cameraController = snapshot.data;
          return Stack(fit: StackFit.passthrough, children: [
            AspectRatio(
                aspectRatio: cameraController.value.aspectRatio,
                child: CameraPreview(cameraController)),
            _overlay(context, bloc),
          ]);
        });
  }

  @override
  void initState() {
    print('[QrCamera] initState');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    print('[QrCamera] dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[QrCamera] didChangeAppLifecycleState $state');
    final controller = bloc.qr.cameraController.value;
    if (state == AppLifecycleState.resumed &&
        (controller == null || !controller.value.isInitialized)) {
      print('[QrCamera] controller == null || !controller.value.isInitialized');
      bloc.qr.initCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      bloc.qr.disposeCamera();
    }
  }

  Widget _overlay(BuildContext context, Bloc bloc) {
    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        decoration: ShapeDecoration(
            shape:
            // _ScannerOverlayShape()
            QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        )
        ),
        // child: Container(
        //   height: 200,
        //   width: 200,
        //   child: MaterialButton(
        //     onPressed: () {
        //       capturePng();
        //     },
        //     child: Text("Press"),
        //     color: Colors.red,
        //   ),
        // ),
      ),
    );
  }

  Future<Uint8List> capturePng() async {
    try {
      print('inside');
      RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData.buffer.asUint8List();
      var bs64 = base64Encode(pngBytes);
      print(pngBytes);
      print(bs64);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ShowImage(
                  image: Image.memory(pngBytes),
                )),
      );
      setState(() {});
      return pngBytes;
    } catch (e) {
      print(e);
    }
  }
}

class ShowImage extends StatefulWidget {
  final Image image;

  const ShowImage({Key key, this.image}) : super(key: key);
  @override
  _ShowImageState createState() => _ShowImageState(this.image);
}

class _ShowImageState extends State<ShowImage> {
  final Image image;

  _ShowImageState(this.image);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 500,
            width: 500,
            child: this.image,
          )
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  }) : assert(
            cutOutSize != null ??
                cutOutSize != null ??
                borderLength <= cutOutSize / 2 + borderWidth * 2,
            "Border can't be larger than ${cutOutSize / 2 + borderWidth * 2}");

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _borderLength = borderLength > cutOutSize / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : borderLength;
    final _cutOutSize = cutOutSize != null && cutOutSize < width
        ? cutOutSize
        : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      // Draw top right corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - _borderLength,
          cutOutRect.top,
          cutOutRect.right,
          cutOutRect.top + _borderLength,
          topRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      // Draw top left corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.top,
          cutOutRect.left + _borderLength,
          cutOutRect.top + _borderLength,
          topLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      // Draw bottom right corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - _borderLength,
          cutOutRect.bottom - _borderLength,
          cutOutRect.right,
          cutOutRect.bottom,
          bottomRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      // Draw bottom left corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.bottom - _borderLength,
          cutOutRect.left + _borderLength,
          cutOutRect.bottom,
          bottomLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

// // based off of flutter_camera_ml_vision:
// // https://github.com/rushio-consulting/flutter_camera_ml_vision/blob/master/example/lib/main.dart
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final Color outlineColor;
  final double borderWidth;
  final double outlineWidth;
  final Color overlayColor;
  final double qViewFinderBorderOffset;
  final double qTopBarMarginTop;
  final double qTopBarMarginBottom;
  final double qBottomBarMarginTop;
  final double qSideBarMarginWidth;

  _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.outlineColor = Colors.white,
    this.borderWidth = 1.0,
    this.outlineWidth = 2.0,
    this.qViewFinderBorderOffset = 36,
    this.qTopBarMarginTop = 20,
    this.qTopBarMarginBottom = 12,
    this.qBottomBarMarginTop = 84,
    this.qSideBarMarginWidth = 36,
    this.overlayColor = const Color(0x80000000),
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    const lineSize = 30;
    final width = rect.width;
    final borderWidthSize = width * 10 / 100;
    final viewFinderCornerOffset = 6;
    final height = rect.height;
    final borderHeightSize = height - (width - borderWidthSize);
    final borderSize = Size(borderWidthSize / 2, borderHeightSize / 2);
    var paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas
    //draw to bar
      ..drawRect(
        Rect.fromLTRB(rect.left, rect.top - qTopBarMarginTop, rect.right,
            borderSize.height + rect.top - qTopBarMarginBottom),
        paint,
      )

    //Draw bottom bar
      ..drawRect(
        Rect.fromLTRB(
            rect.left,
            rect.bottom - borderSize.height - qBottomBarMarginTop,
            rect.right,
            rect.bottom),
        paint,
      )

    //Left Side Bar
      ..drawRect(
        Rect.fromLTRB(
            rect.left,
            rect.top + borderSize.height - qTopBarMarginBottom,
            rect.left + borderSize.width + qSideBarMarginWidth,
            rect.bottom - borderSize.height - qBottomBarMarginTop),
        paint,
      )

    //Right side Bar
      ..drawRect(
        Rect.fromLTRB(
            rect.right - borderSize.width - qSideBarMarginWidth,
            rect.top + borderSize.height - qTopBarMarginBottom,
            rect.right,
            rect.bottom - borderSize.height - qBottomBarMarginTop),
        paint,
      );

    paint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth;

    canvas
      ..drawRect(
        Rect.fromLTRB(
            rect.left + borderSize.width + qSideBarMarginWidth,
            borderSize.height + rect.top - qTopBarMarginBottom,
            rect.right - borderSize.width - qSideBarMarginWidth,
            rect.bottom - borderSize.height - qBottomBarMarginTop),
        paint,
      );

    paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final borderOffset = borderWidth / 2;
    final viewfinderRect = Rect.fromLTRB(
        borderSize.width + borderOffset,
        borderSize.height + borderOffset + rect.top - 48,
        width - borderSize.width - borderOffset,
        height - borderSize.height - borderOffset + rect.top - 48);

    // draw top right corner
    canvas
      ..drawPath(
          Path()
            ..moveTo(
                viewfinderRect.right -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset,
                viewfinderRect.top +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset)
            ..lineTo(
                viewfinderRect.right -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset,
                viewfinderRect.top +
                    lineSize +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset),
          paint)
      ..drawPath(
          Path()
            ..moveTo(
                viewfinderRect.right -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset,
                viewfinderRect.top +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset)
            ..lineTo(
                viewfinderRect.right -
                    lineSize -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset,
                viewfinderRect.top +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset),
          paint)
      ..drawPoints(
        PointMode.points,
        [
          Offset(
              viewfinderRect.right -
                  qViewFinderBorderOffset +
                  viewFinderCornerOffset,
              viewfinderRect.top +
                  qViewFinderBorderOffset -
                  viewFinderCornerOffset)
        ],
        paint,
      )

    // draw top left corner
      ..drawPath(
          Path()
            ..moveTo(
                viewfinderRect.left +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset,
                viewfinderRect.top +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset)
            ..lineTo(
                viewfinderRect.left +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset,
                viewfinderRect.top +
                    lineSize +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset),
          paint)
      ..drawPath(
          Path()
            ..moveTo(
                viewfinderRect.left +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset,
                viewfinderRect.top +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset)
            ..lineTo(
                viewfinderRect.left +
                    lineSize +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset,
                viewfinderRect.top +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset),
          paint)
      ..drawPoints(
        PointMode.points,
        [
          Offset(
              viewfinderRect.left +
                  qViewFinderBorderOffset -
                  viewFinderCornerOffset,
              viewfinderRect.top +
                  qViewFinderBorderOffset -
                  viewFinderCornerOffset)
        ],
        paint,
      )

    // draw bottom right corner
      ..drawPath(
          Path()
            ..moveTo(
                viewfinderRect.right -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset,
                viewfinderRect.bottom -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset)
            ..lineTo(
                viewfinderRect.right -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset,
                viewfinderRect.bottom -
                    lineSize -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset),
          paint)
      ..drawPath(
          Path()
            ..moveTo(
                viewfinderRect.right -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset,
                viewfinderRect.bottom -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset)
            ..lineTo(
                viewfinderRect.right -
                    lineSize -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset,
                viewfinderRect.bottom -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset),
          paint)
      ..drawPoints(
        PointMode.points,
        [
          Offset(
              viewfinderRect.right -
                  qViewFinderBorderOffset +
                  viewFinderCornerOffset,
              viewfinderRect.bottom -
                  qViewFinderBorderOffset +
                  viewFinderCornerOffset)
        ],
        paint,
      )

    // draw bottom left corner
      ..drawPath(
          Path()
            ..moveTo(
                viewfinderRect.left +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset,
                viewfinderRect.bottom -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset)
            ..lineTo(
                viewfinderRect.left +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset,
                viewfinderRect.bottom -
                    lineSize -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset),
          paint)
      ..drawPath(
          Path()
            ..moveTo(
                viewfinderRect.left +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset,
                viewfinderRect.bottom -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset)
            ..lineTo(
                viewfinderRect.left +
                    lineSize +
                    qViewFinderBorderOffset -
                    viewFinderCornerOffset,
                viewfinderRect.bottom -
                    qViewFinderBorderOffset +
                    viewFinderCornerOffset),
          paint)
      ..drawPoints(
        PointMode.points,
        [
          Offset(
              viewfinderRect.left +
                  qViewFinderBorderOffset -
                  viewFinderCornerOffset,
              viewfinderRect.bottom -
                  qViewFinderBorderOffset +
                  viewFinderCornerOffset)
        ],
        paint,
      );
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
