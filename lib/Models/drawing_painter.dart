import 'package:flutter/cupertino.dart';
import 'package:unote/Models/drawing_canvas.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:provider/provider.dart';

class DrawingCanvas extends StatefulWidget {
  final List<Stroke> strokes;

  DrawingCanvas(this.strokes);

  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        context.read<PageManager>().addPoint(details.localPosition);
      },
      onPanEnd: (details) {
        context.read<PageManager>().endLine();
      },
      child: CustomPaint(
        painter: DrawingPainter(widget.strokes),
        size: Size.infinite,
      ),
    );
  }
}
