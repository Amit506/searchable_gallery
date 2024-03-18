import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:searchable_gallery/pages/view_image.dart';
import 'package:searchable_gallery/provider/file_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>  with AutomaticKeepAliveClientMixin{
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: const [IconButton(
          onPressed: null,
          icon: Icon(Icons.image_search_rounded))],
      ),
      floatingActionButton: const FloatingActionButton(onPressed: null,child: Icon(Icons.search) ,),
      body: Consumer<FileProvider>(
        builder: (context, fileProvider, child) {
          final files = fileProvider.files;
          if (files.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return GridView.custom(
            gridDelegate: SliverQuiltedGridDelegate(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              repeatPattern: QuiltedGridRepeatPattern.inverted,
              pattern: [
                const QuiltedGridTile(2, 2),
                const QuiltedGridTile(1, 1),
                const QuiltedGridTile(1, 1),
              ],
            ),
            childrenDelegate: SliverChildBuilderDelegate((_, index) {
              final image = files[index];

              return Container(
                decoration: const BoxDecoration(),
                child: Hero(
                  tag: image.path,
                  child: Material(
                    child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ViewImage(file: File(image.path))));
                        },
                        child: Image.file(
                          File(image.path),
                          fit: BoxFit.cover,
                        )),
                  ),
                ),
              );
            }, childCount: files.length),
          );
        },
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}
