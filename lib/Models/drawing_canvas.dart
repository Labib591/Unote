import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unote/Models/page_manager.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final ShapeType currentShape;
  final Color currentColor;
  final double currentThickness;

  DrawingPainter(
    this.strokes, {
    required this.currentShape,
    required this.currentColor,
    required this.currentThickness,
  });

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
  final List<Stroke> currentPage;
  
  const DrawingCanvas({
    super.key,
    required this.currentPage,
  });
  
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PageManager>(
      builder: (context, pageManager, child) {
        return GestureDetector(
          onPanStart: (details) {
            pageManager.addPoint(details.localPosition);
          },
          onPanUpdate: (details) {
            pageManager.addPoint(details.localPosition);
          },
          onPanEnd: (details) {
            pageManager.endLine();
          },
          child: CustomPaint(
            painter: DrawingPainter(
              widget.currentPage,
              currentColor: pageManager.currentColor,
              currentThickness: pageManager.currentThickness,
              currentShape: ShapeType.none,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}
