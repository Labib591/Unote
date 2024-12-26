import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unote/Models/page_manager.dart';

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Offset? shapeStart;
  final Offset? shapeEnd;
  final ShapeType currentShape;
  final Color currentColor;
  final double currentThickness;

  DrawingPainter(
    this.strokes, {
    this.shapeStart,
    this.shapeEnd,
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
  final List<Stroke> strokes;
  DrawingCanvas(this.strokes);
  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PageManager>(
      builder: (context, pageManager, child) {
        print('Current shape type: ${pageManager.currentShape}');
        
        return Container(
          color: Colors.black,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              print('Pan start: ${details.localPosition}');
              if (pageManager.currentShape != ShapeType.none) {
                pageManager.startShape(details.localPosition);
              } else {
                pageManager.addPoint(details.localPosition);
              }
            },
            onPanUpdate: (details) {
              print('Pan update: ${details.localPosition}');
              if (pageManager.currentShape != ShapeType.none) {
                pageManager.updateShape(details.localPosition);
              } else {
                pageManager.addPoint(details.localPosition);
              }
            },
            onPanEnd: (details) {
              print('Pan end');
              if (pageManager.currentShape != ShapeType.none) {
                pageManager.endShape();
              } else {
                pageManager.endLine();
              }
            },
            child: CustomPaint(
              painter: DrawingPainter(
                widget.strokes,
                shapeStart: pageManager.shapeStart,
                shapeEnd: pageManager.shapeEnd,
                currentShape: pageManager.currentShape,
                currentColor: pageManager.currentColor,
                currentThickness: pageManager.currentThickness,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}
