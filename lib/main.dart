import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:searchable_gallery/pages/home_page.dart';
import 'package:searchable_gallery/provider/file_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
                ChangeNotifierProvider<FileProvider>( create: (context) => FileProvider()),

      ],
      child: MaterialApp(
       theme: FlexThemeData.light(scheme: FlexScheme.aquaBlue),
        // The Mandy red, dark theme.
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed),
        home: const HomePage(),
      ),
    );
  }
}
