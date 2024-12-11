import 'package:flutter/cupertino.dart';
import 'package:unote/Models/drawing_canvas.dart';

class DrawingCanvas extends StatefulWidget {
  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset?> _points = []; // Allow null values for stroke separation

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _points.add(details.localPosition); // Add points while drawing
        });
      },
      onPanEnd: (details) {
        setState(() {
          _points.add(null); // Add null to separate strokes
        });
      },
      child: CustomPaint(
        painter: DrawingPainter(_points), // Pass the points list to the painter
        size: Size.infinite, // Use infinite size for the canvas
      ),
    );
  }
}
