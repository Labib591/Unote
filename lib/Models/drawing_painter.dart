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

  DrawingPainter(this.strokes, {
    required this.currentColor,
    required this.currentThickness,
    required this.currentShape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.src);

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.isEraser ? Colors.black : stroke.color
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length < 2) continue;

      switch (stroke.penStyle) {
        case PenStyle.normal:
          _drawNormalLine(canvas, stroke.points, paint);
          break;
        case PenStyle.dotted:
          _drawDottedLine(canvas, stroke.points, paint);
          break;
        case PenStyle.dashed:
          _drawDashedLine(canvas, stroke.points, paint);
          break;
        case PenStyle.double:
          _drawDoubleLine(canvas, stroke.points, paint);
          break;
      }
    }
  }

  void _drawNormalLine(Canvas canvas, List<Offset?> points, Paint paint) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  void _drawDottedLine(Canvas canvas, List<Offset?> points, Paint paint) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final distance = (points[i + 1]! - points[i]!).distance;
        final unitVector = (points[i + 1]! - points[i]!) / distance;
        
        for (double d = 0; d < distance; d += 10) {
          final dot = points[i]! + unitVector * d;
          canvas.drawCircle(dot, paint.strokeWidth / 2, paint);
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, List<Offset?> points, Paint paint) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final distance = (points[i + 1]! - points[i]!).distance;
        final unitVector = (points[i + 1]! - points[i]!) / distance;
        
        for (double d = 0; d < distance; d += 20) {
          final start = points[i]! + unitVector * d;
          final end = points[i]! + unitVector * min(d + 10, distance);
          canvas.drawLine(start, end, paint);
        }
      }
    }
  }

  void _drawDoubleLine(Canvas canvas, List<Offset?> points, Paint paint) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final vector = points[i + 1]! - points[i]!;
        final distance = vector.distance;
        final perpendicular = Offset(-vector.dy, vector.dx) * (2 / distance);
        
        canvas.drawLine(points[i]! + perpendicular, points[i + 1]! + perpendicular, paint);
        canvas.drawLine(points[i]! - perpendicular, points[i + 1]! - perpendicular, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
