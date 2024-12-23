import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
      return Offset(point['x'], point['y']);
    }).toList();
  }

  // Save note to file
  static Future<void> saveNote(List<List<Offset?>> pages, String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception('Failed to access external storage');

      // Create a custom directory for your notes
      final noteDirectory = Directory('${directory.path}/UNotes');
      if (!await noteDirectory.exists()) {
        await noteDirectory.create(recursive: true);
      }

      final file = File('${noteDirectory.path}/$fileName.unote');
      print('Saving file to: ${file.path}'); // For debugging

      final noteData = {
        'pages': pages.map((page) => _pointsToJson(page)).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(jsonEncode(noteData));
    } catch (e) {
      print('Error saving note: $e');
      throw Exception('Failed to save note');
    }
  }

  // Load note from file
  static Future<List<List<Offset?>>> loadNote(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.unote');

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
      throw Exception('Failed to load note');
    }
  }
}
