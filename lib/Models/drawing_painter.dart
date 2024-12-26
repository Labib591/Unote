import 'package:flutter/material.dart';
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
        painter: DrawingPainter(
          widget.strokes,
          currentShape: ShapeType.none,
          currentColor: Colors.white,
          currentThickness: 2.0,
        ),
        size: Size.infinite,
      ),
    );
  }
}

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
    canvas.drawColor(Colors.black, BlendMode.src);

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.isEraser ? Colors.black : stroke.color
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

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

    // Draw shape preview
    if (shapeStart != null && shapeEnd != null && currentShape != ShapeType.none) {
      print('Drawing shape preview: $currentShape'); // Debug print
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentThickness
        ..style = PaintingStyle.stroke;

      switch (currentShape) {
        case ShapeType.line:
          canvas.drawLine(shapeStart!, shapeEnd!, paint);
          break;

        case ShapeType.rectangle:
          canvas.drawRect(Rect.fromPoints(shapeStart!, shapeEnd!), paint);
          break;

        case ShapeType.circle:
          final center = Offset(
            (shapeStart!.dx + shapeEnd!.dx) / 2,
            (shapeStart!.dy + shapeEnd!.dy) / 2,
          );
          final radius = (shapeEnd! - shapeStart!).distance / 2;
          canvas.drawCircle(center, radius, paint);
          break;

        case ShapeType.triangle:
          final path = Path()
            ..moveTo(shapeStart!.dx, shapeStart!.dy)
            ..lineTo(shapeEnd!.dx, shapeEnd!.dy)
            ..lineTo(
              shapeStart!.dx - (shapeEnd!.dx - shapeStart!.dx),
              shapeEnd!.dy,
            )
            ..close();
          canvas.drawPath(path, paint);
          break;

        case ShapeType.arrow:
          final delta = shapeEnd! - shapeStart!;
          final length = delta.distance;
          final unitVector = delta / length;
          final perpendicular = Offset(-unitVector.dy, unitVector.dx);
          
          // Draw arrow shaft
          canvas.drawLine(shapeStart!, shapeEnd!, paint);
          
          // Draw arrow head
          final arrowHead = shapeEnd! - unitVector * (length * 0.2);
          canvas.drawLine(shapeEnd!, arrowHead + perpendicular * (length * 0.1), paint);
          canvas.drawLine(shapeEnd!, arrowHead - perpendicular * (length * 0.1), paint);
          break;

        case ShapeType.none:
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
          final end = points[i]! + unitVector * (d + 10);
          if (d + 10 <= distance) {
            canvas.drawLine(start, end, paint);
          }
        }
      }
    }
  }

  void _drawDoubleLine(Canvas canvas, List<Offset?> points, Paint paint) {
    final offset = 2.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final vector = points[i + 1]! - points[i]!;
        final distance = vector.distance;
        final perpendicular = Offset(-vector.dy, vector.dx) * (offset / distance);
        
        canvas.drawLine(points[i]! + perpendicular, points[i + 1]! + perpendicular, paint);
        canvas.drawLine(points[i]! - perpendicular, points[i + 1]! - perpendicular, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true;
  }
}
