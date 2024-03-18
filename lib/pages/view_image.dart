import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
class ViewImage extends StatefulWidget {
  final File file;
  const ViewImage({super.key, required this.file});

  @override
  State<ViewImage> createState() => _ViewImageState();
}

class _ViewImageState extends State<ViewImage> {

  Future<Size> getImageSize(File file) async {
  Completer<ui.Image> completer = Completer();
  Image image = Image(image: FileImage(file));
  image.image.resolve(const ImageConfiguration()).addListener(ImageStreamListener((info, _) {
    completer.complete(info.image);
  }));

  ui.Image img = await completer.future;
  return Size(img.width.toDouble(), img.height.toDouble());
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  
      ),

      body: Center(
        child: FutureBuilder<Size>(
          future: getImageSize(widget.file),
          builder: (context,future) {
            if(future.data!=null){
            return CropImage(image: widget.file,size: future.data!,);
            }
            return const SizedBox();
          }
        ),
      ),
    );
  }
}
class CropPainter extends CustomPainter {
  final List<Offset> points;

  CropPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth=5
      ..strokeCap=StrokeCap.round
      ..style=PaintingStyle.stroke;

    Path path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length-2; i++) {
        final p0= points[i];
        final p1= points[i+1];
        path.quadraticBezierTo(p0.dx,p0.dy,(p0.dx+p1.dx)/2,(p0.dy+p1.dy)/2);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
class CropImage extends StatefulWidget {
  final File image;
  final Size size;
  const CropImage({super.key, required this.image, required this.size});

  @override
  State<CropImage> createState() => _CropImageState();
}

class _CropImageState extends State<CropImage> {
  List<Offset> _points = [];

  @override
  Widget build(BuildContext context) {
    return  Container(
      height:widget.size.height,
      width: widget.size.width,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
      
      ),
      child: Listener(
          onPointerDown: (details) {
            // RenderBox renderBox = context.findRenderObject() as RenderBox;
            // final position = renderBox.globalToLocal(details.position);
            
            setState(() {
             _points=List.from([details.position]);
            });
            log(details.toString());
          },
          onPointerMove: (details) {
            //          RenderBox renderBox = context.findRenderObject() as RenderBox;
            //                      final position = renderBox.globalToLocal(details.position);

            // final positionn = renderBox.globalToLocal(details.position);
            setState(() {
              _points.add(details.position);
            });
            // Ensure a minimum number of points for drawing
            // if (_points.length < 3) {
            //   setState(() {
            //     _points.clear();
            //   });
            // }
          },
          child: Stack(
            clipBehavior: Clip.antiAlias,
            // alignment: Alignment.center,
            children:[ 
              Image.file(widget.image),
              CustomPaint(
              painter: CropPainter(_points),
             
            ),
            ]
          ),
        
      ),
    );
  }
}
