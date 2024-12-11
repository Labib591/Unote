import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:unote/Models/drawing_painter.dart';
import 'package:unote/widgets/custom_toolbar.dart';

class editorScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("MY NOTE"),
      ),
      body: Stack(
        children: [
          DrawingCanvas(),
        ],
      ),
    );
  }
}