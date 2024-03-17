import 'dart:io';

import 'package:flutter/material.dart';

class ViewImage extends StatefulWidget {
  final File file;
  const ViewImage({super.key, required this.file});

  @override
  State<ViewImage> createState() => _ViewImageState();
}

class _ViewImageState extends State<ViewImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to the previous screen
              },
              child: Text('Go Back'),
            ),
      ),

      body: Center(
        child: Hero(
          tag: widget.file.path,
          child: Image.file(widget.file,fit: BoxFit.contain,)),
      ),
    );
  }
}