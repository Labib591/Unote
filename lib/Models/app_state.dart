import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppState extends ChangeNotifier {
  String? _lastOpenedNote;
  
  String? get lastOpenedNote => _lastOpenedNote;

  Future<void> setLastOpenedNote(String? fileName) async {
    _lastOpenedNote = fileName;
    final prefs = await SharedPreferences.getInstance();
    if (fileName != null) {
      await prefs.setString('last_note', fileName);
    } else {
      await prefs.remove('last_note');
    }
    notifyListeners();
  }

  Future<void> loadLastState() async {
    final prefs = await SharedPreferences.getInstance();
    _lastOpenedNote = prefs.getString('last_note');
    notifyListeners();
  }
} 