import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class ViewImage extends StatefulWidget {
  final File file;
  const ViewImage({super.key, required this.file});

  @override
  State<ViewImage> createState() => _ViewImageState();
}

class _ViewImageState extends State<ViewImage> {
  late WebViewController controller;
  ValueNotifier<int> progressValue = ValueNotifier(0);
  ValueNotifier<bool> loading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
            progressValue.value = progress;
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );
    loadLottieComposition('assets/loading.json');
  }

  Future<Size> getImageSize(File file) async {
    Completer<ui.Image> completer = Completer();
    Image image = Image(image: FileImage(file));
    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, _) {
      completer.complete(info.image);
    }));

    ui.Image img = await completer.future;
    log('size1 ${img.height}: ${img.width}');
    return calculateImageSize(img.width.toDouble(), img.height.toDouble(),
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(widget.file.path)),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<Size>(
                future: getImageSize(widget.file),
                builder: (context, future) {
                  if (future.data != null) {
                    log('size2 ${future.data?.height}: ${future.data?.width}');

                    return CropImage(
                      image: widget.file,
                      size: future.data!,
                      onLoadinChange: (value) {
                        loading.value = value;
                      },
                      onSearch: (searchImage) async {
                        var headers = {
                          'Authorization':
                              'Bearer public_W142iWnGXHeSas5HJrzBkA9cBdsh'
                        };
                        var request = http.MultipartRequest(
                            'POST',
                            Uri.parse(
                                'https://api.bytescale.com/v2/accounts/W142iWn/uploads/form_data'));
                        request.files.add(await http.MultipartFile.fromPath(
                            'file', searchImage.path));
                        request.headers.addAll(headers);

                        http.StreamedResponse response = await request.send();

                        if (response.statusCode == 200) {
                          log(response.statusCode.toString());
                          String responseBody =
                              await response.stream.bytesToString();

                          // Parse the JSON string to a Map
                          Map<String, dynamic> responseData =
                              jsonDecode(responseBody);
                          final uploadedUrl =
                              (responseData['files'] as List).first['fileUrl'];
                          final url =
                              'https://lens.google.com/uploadbyurl?url=$uploadedUrl';
                          log(url.toString());
                          loading.value = false;
                          _showWebViewBottomSheet(context, url: url);
                        } else {
                          log(response.reasonPhrase.toString());
                        }
                      },
                    );
                  }
                  return const SizedBox();
                }),
            ValueListenableBuilder(
                valueListenable: loading,
                builder: (context, load, child) {
                  if (load) {
                    return SizedBox(
                      height: 100,
                      width: 100,
                      child: Lottie(
                        composition: lottieComposition,
                      ),
                    );
                  }
                  return SizedBox();
                }),
          ],
        ),
      ),
    );
  }

  void _showWebViewBottomSheet(BuildContext context,
      {String url =
          'https://lens.google.com/uploadbyurl?url=https://upcdn.io/W142iWn/raw/uploads/2024/03/18/4kk8qKvcJR-cropped.png'}) {
    controller.loadRequest(Uri.parse(url));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      )),
      builder: (context) {
        return DraggableScrollableSheet(
          maxChildSize: 0.9,
          initialChildSize: 0.8,
          minChildSize: 0.4,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Column(
              children: [
                SizedBox(
                  height: 30,
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 6,
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ),
                ValueListenableBuilder(
                    valueListenable: progressValue,
                    builder: (context, progress, child) {
                      log('progress : +$progress');
                      if (progress <= 0 || progress >= 100) {
                        return SizedBox();
                      }
                      return LinearProgressIndicator(
                        value: progress.toDouble() / 100,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                      );
                    }),
                Expanded(
                    child: WebViewWidget(
                  controller: controller,
                  gestureRecognizers: Set()
                    ..add(
                      Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer(),
                      ), // or null
                    ),
                )),
              ],
            );
          },
        );
      },
    );
  }

  late LottieComposition lottieComposition;
  Future<void> loadLottieComposition(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    lottieComposition = await LottieComposition.fromByteData(data);
  }
}

class CropImage extends StatefulWidget {
  final File image;
  final Size size;
  final Function(File file) onSearch;
  final Function(bool value) onLoadinChange;
  const CropImage(
      {super.key,
      required this.image,
      required this.size,
      required this.onSearch,
      required this.onLoadinChange});

  @override
  State<CropImage> createState() => _CropImageState();
}

class _CropImageState extends State<CropImage> {
  List<Offset> _points = [];
  File? cropFile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size.height,
      width: widget.size.width,
      child: GestureDetector(
        onTap: () {
          _points.clear();
        },
        onPanDown: (details) {
          // RenderBox renderBox = context.findRenderObject() as RenderBox;
          // final position = renderBox.globalToLocal(details.position);

          setState(() {
            _points = List.from([details.localPosition]);
          });
        },
        onPanUpdate: (details) {
          // RenderBox renderBox = context.findRenderObject() as RenderBox;
          // final position = renderBox.globalToLocal(details.localPosition);
          final position = details.localPosition;
          if (position.dx > widget.size.width ||
              position.dx < 0 ||
              position.dy > widget.size.height ||
              position.dy < 0) {
            return;
          }
          setState(() {
            _points.add(details.localPosition);
          });
        },
        onPanEnd: (details) async {
          if (_points.isEmpty || _points.length < 10) {
            return;
          }
          widget.onLoadinChange.call(true);
          final dir = await getApplicationDocumentsDirectory();

          cropFile = await compute(
            crop,
            [
              widget.image.path,
              widget.size.width,
              widget.size.height,
              _points,
              dir.path
            ],
          );
          // crop(widget.image, widget.size);
          // widget.onLoadinChange.call(false);
          widget.onSearch.call(cropFile!);
        },
        child: CustomPaint(
          foregroundPainter: CropPainter(
            _points,
          ),
          size: widget.size,
          child: Image.file(
            widget.image,
            //  cropFile==null? widget.image:cropFile!,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

Size calculateImageSize(double originalWidth, double originalHeight,
    double screenWidth, double screenHeight) {
  final imageAspectRatio = originalWidth / originalHeight;

  double imageWidth, imageHeight;

  if (screenWidth / screenHeight > imageAspectRatio) {
    imageWidth = screenHeight * imageAspectRatio;
    imageHeight = screenHeight;
  } else {
    imageWidth = screenWidth;
    imageHeight = screenWidth / imageAspectRatio;
  }

  return Size(imageWidth, imageHeight);
}

double convertXCoordinate(
    double xCoordinate, double imageWidth, double screenWidth) {
  double ratio = imageWidth / screenWidth;
  return xCoordinate * ratio;
}

double convertYCoordinate(
    double yCoordinate, double imageHeight, double screenHeight) {
  double ratio = imageHeight / screenHeight;
  return yCoordinate * ratio;
}

class CropPainter extends CustomPainter {
  final List<Offset> points;
  // final ui.Image myBackground;

  CropPainter(
    this.points,
  );

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Path path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length - 2; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        path.quadraticBezierTo(
            p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

Future<File> crop(List<dynamic> d) async {
  String fileName = d[0] as String;
  double width = d[1] as double;
  double height = d[2] as double;
  final _points = d[3] as List<Offset>;
  final dirPath = d[4] as String;

  File file = File(fileName);
  Size size = Size(width, height);
  Uint8List data = await file.readAsBytes();
  img.Image origginalImage = img.decodeImage(data)!;

  double minX = double.infinity, minY = double.infinity;
  double maxX = 0, maxY = 0;
  for (Offset point in _points) {
    minX = point.dx < minX ? point.dx : minX;
    minY = point.dy < minY ? point.dy : minY;
    maxX = point.dx > maxX ? point.dx : maxX;
    maxY = point.dy > maxY ? point.dy : maxY;
  }

  minX = convertXCoordinate(minX, origginalImage.width.toDouble(), size.width);
  maxX = convertXCoordinate(maxX, origginalImage.width.toDouble(), size.width);

  minY =
      convertXCoordinate(minY, origginalImage.height.toDouble(), size.height);

  maxY =
      convertXCoordinate(maxY, origginalImage.height.toDouble(), size.height);

  log('size ${origginalImage.height}: ${origginalImage.width}');
  Uint8List croppedImage = img.encodePng(img.copyCrop(
    origginalImage,
    x: (minX).toInt(),
    y: (minY).toInt(),
    width: (maxX - minX).toInt(),
    height: (maxY - minY).toInt(),
  ));
  final croppedFile = File(dirPath + '/cropped.png');
  await croppedFile.writeAsBytes(croppedImage);

  return croppedFile;
}
