import 'package:flutter/material.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:provider/provider.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;

  DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.isEraser ? Colors.black : stroke.color
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

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
