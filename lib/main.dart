import 'package:flutter/material.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:unote/screens/editor_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => PageManager(),
    child: MyApp(),
  ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: editorScreen(),
    );}}