import 'package:flutter/material.dart';
import 'package:test_paint/ui/painter/app_painter_screen.dart';
import 'package:test_paint/ui/painter/app_painter_wm.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AppPainterScreen(wm: AppPainterWidgetModel(),),
    );
  }
}
