import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:path/path.dart' as path;

class NoteSaver {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _getFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName.json');
  }

  static Future<void> saveNote(String fileName, List<List<Stroke>> pages) async {
    try {
      final file = await _getFile(fileName);
      final noteData = {
        'pages': pages.map((page) => page.map((stroke) => {
          'points': stroke.points.map((p) => p?.dx != null ? {'x': p!.dx, 'y': p.dy} : null).toList(),
          'color': stroke.color.value,
          'thickness': stroke.thickness,
          'isEraser': stroke.isEraser,
        }).toList()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final jsonString = jsonEncode(noteData);
      await file.writeAsString(jsonString);
      print('Saved successfully to: ${file.path}');
    } catch (e) {
      print('Save error: $e');
      throw e;
    }
  }

  static Future<List<String>> listNotes() async {
    try {
      final directory = Directory(await _localPath);
      final files = await directory.list().toList();
      return files
          .where((file) => file.path.endsWith('.json'))
          .map((file) => path.basename(file.path).replaceAll('.json', ''))
          .toList();
    } catch (e) {
      print('Error listing notes: $e');
      return [];
    }
  }

  static Future<List<List<Stroke>>> loadNote(String fileName) async {
    try {
      final file = await _getFile(fileName);
      final contents = await file.readAsString();
      final data = jsonDecode(contents);
      
      return (data['pages'] as List).map((page) {
        return (page as List).map((strokeData) {
          final points = (strokeData['points'] as List).map((p) {
            if (p == null) return null;
            return Offset(p['x'] as double, p['y'] as double);
          }).toList();

          return Stroke(
            points,
            Color(strokeData['color'] as int),
            (strokeData['thickness'] as num).toDouble(),
            strokeData['isEraser'] as bool,
          );
        }).toList();
      }).toList();
    } catch (e) {
      print('Error loading note: $e');
      throw e;
    }
  }

  static Future<String> getNotesDirectory() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception('Failed to access external storage');
      return path.join(directory.path, 'UNotes');
    } else if (Platform.isWindows) {
      final directory = await getApplicationDocumentsDirectory();
      return path.join(directory.path, 'UNotes');
    }
    throw Exception('Unsupported platform');
  }

  static Future<void> deleteNote(String fileName) async {
    final file = await _getFile(fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
