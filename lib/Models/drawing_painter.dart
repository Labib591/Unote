import 'package:flutter/cupertino.dart';
import 'package:unote/Models/drawing_canvas.dart';

class DrawingCanvas extends StatefulWidget {
  final List<Offset?> points;

  DrawingCanvas(this.points);

  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          widget.points.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        widget.points.add(null);
      },
      child: CustomPaint(
        painter: DrawingPainter(widget.points),
        size: Size.infinite,
      ),
    );
  }
}
