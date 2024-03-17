import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path;

class FileService {
  List<String> allowedExtensions = ['jpg', 'png', 'jpeg', 'webp'];
  Future<List<FileSystemEntity>> loadAllFiles() async {
    Directory dir = await Directory('/storage/emulated/0/DCIM');
    List<FileSystemEntity> files = <FileSystemEntity>[];
    // for (Directory dir in storages) {
    log(dir.toString());

    final allFilesInPath = await _getAllFilesInPathIsolate(
      dir.path,
    );

    files.addAll(allFilesInPath);
    // }
    log(files.length.toString());
    return files;
  }

  Future<List<FileSystemEntity>> _getAllFilesInPathIsolate(String path) async {
    return await compute(_getAllFilesInPath, path);
  }

  Future<List<FileSystemEntity>> _getAllFilesInPath(String path) async {
    List<FileSystemEntity> files = <FileSystemEntity>[];

    try {
      Directory d = Directory(path);
      List<FileSystemEntity> l = d.listSync();
      log("files length ${files.length}");
      for (FileSystemEntity file in l) {
        if (FileSystemEntity.isFileSync(file.path)) {
          if (allowedExtensions.any((element) => file.path.endsWith(element))) {
            files.add(file);
          }
        } else {
          final recursiveList= await _getAllFilesInPath(file.path);
          files.addAll(recursiveList.reversed.toList());
        }
      }
    } catch (e) {
      log(e.toString());
    }
    return files;
  }

  // Future<List<Directory>> _getStorageList() async {
  //   List<Directory> storages =
  //       (await path.getExternalStorageDirectories()) ?? [];
  //   log(storages.toString());
  //   final paths = storages.map((Directory e) {
  //     final List<String> splitedPath = e.path.split("/");
  //     return Directory(splitedPath
  //         .sublist(0, splitedPath.indexWhere((element) => element == "Android"))
  //         .join("/"));
  //   }).toList();
  //   log(paths.toString());
  //   return paths;
  // }
}
