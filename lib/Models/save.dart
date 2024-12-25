import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:unote/Models/page_manager.dart';

class NoteSaver {
  // Converts list of points to JSON-compatible format
  static List<Map<String, dynamic>?> _pointsToJson(List<Offset?> points) {
    return points.map((offset) {
      if (offset == null) return null;
      return {
        'x': offset.dx,
        'y': offset.dy,
      };
    }).toList();
  }

  // Converts JSON data back to list of points
  static List<Offset?> _pointsFromJson(List<dynamic> jsonPoints) {
    return jsonPoints.map((point) {
      if (point == null) return null;
      return Offset(
        (point['x'] as num).toDouble(),
        (point['y'] as num).toDouble(),
      );
    }).toList();
  }

  // Save note to file
  static Future<void> saveNote(List<List<Stroke>> pages, String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception('Failed to access external storage');

      final noteDirectory = Directory('${directory.path}/UNotes');
      if (!await noteDirectory.exists()) {
        await noteDirectory.create(recursive: true);
      }

      final file = File('${noteDirectory.path}/$fileName.unote');
      
      final noteData = {
        'pages': pages.map((page) => page.map((stroke) => {
          'points': (stroke as Stroke).points.map((p) => p?.dx != null ? {'x': p!.dx, 'y': p.dy} : null).toList(),
          'color': stroke.color.value,
          'thickness': stroke.thickness,
          'isEraser': stroke.isEraser,
        }).toList()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(jsonEncode(noteData));
      
      // Save preview of the first page
      if (pages.isNotEmpty) {
        await savePreview(pages[0], fileName);
      }
    } catch (e) {
      print('Error saving note: $e');
      throw Exception('Failed to save note');
    }
  }

  // Load note from file
  static Future<List<List<Offset?>>> loadNote(String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception('Failed to access external storage');

      final file = File('${directory.path}/UNotes/$fileName.unote');

      if (!await file.exists()) {
        throw Exception('Note file does not exist');
      }

      final jsonString = await file.readAsString();
      final noteData = jsonDecode(jsonString);

      // Convert JSON data back to list of pages with points
      return (noteData['pages'] as List).map<List<Offset?>>((page) {
        return _pointsFromJson(page as List);
      }).toList();
    } catch (e) {
      print('Error loading note: $e');
      throw Exception('Failed to load note: $e');
    }
  }

  static Future<void> savePreview(List<Stroke> strokes, String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception('Failed to access external storage');

      final previewDirectory = Directory('${directory.path}/UNotes/previews');
      if (!await previewDirectory.exists()) {
        await previewDirectory.create(recursive: true);
      }

      // Create a picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw black background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 200, 200),
        Paint()..color = Colors.black,
      );

      // Scale points to fit preview
      final scale = 200 / 1000; // Assuming original canvas is 1000x1000

      // Draw the points
      for (var stroke in strokes) {
        final paint = Paint()
          ..color = stroke.isEraser ? Colors.black : stroke.color
          ..strokeWidth = stroke.thickness * scale
          ..strokeCap = StrokeCap.round;

        for (int i = 0; i < stroke.points.length - 1; i++) {
          if (stroke.points[i] != null && stroke.points[i + 1] != null) {
            canvas.drawLine(
              Offset(stroke.points[i]!.dx * scale, stroke.points[i]!.dy * scale),
              Offset(stroke.points[i + 1]!.dx * scale, stroke.points[i + 1]!.dy * scale),
              paint,
            );
          }
        }
      }

      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(200, 200);
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (pngBytes == null) throw Exception('Failed to generate preview');

      // Save preview image
      final previewFile = File('${previewDirectory.path}/$fileName.png');
      await previewFile.writeAsBytes(pngBytes.buffer.asUint8List());
    } catch (e) {
      print('Error saving preview: $e');
    }
  }
}
