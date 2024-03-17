import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:searchable_gallery/Service/FileService.dart';

class FileProvider extends ChangeNotifier {
  late FileService fileService;

  FileProvider() {
    fileService = FileService();
    load();
  }
  List<FileSystemEntity> files = [];
  load() async {
    log("loading files");
    files = await fileService.loadAllFiles();
        log("finished loading : ${files.length}");

    notifyListeners();
  }
}
