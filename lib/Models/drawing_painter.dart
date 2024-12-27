import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:unote/Models/drawing_canvas.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:provider/provider.dart';
import 'dart:math';

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
              backgroundColor: pageManager.backgroundColor,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Color currentColor;
  final double currentThickness;
  final ShapeType currentShape;
  final Color backgroundColor;

  DrawingPainter(
    this.strokes, {
    required this.currentColor,
    required this.currentThickness,
    required this.currentShape,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.isEraser ? backgroundColor : stroke.color
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
}
