import 'package:flutter/material.dart';
import 'package:unote/Models/save.dart';

class Stroke {
  final List<Offset?> points;
  final Color color;
  final double thickness;
  final bool isEraser;

  Stroke(this.points, this.color, this.thickness, this.isEraser);
}

class PageManager extends ChangeNotifier{
  List<List<Stroke>> _pages = [[]];
  int _currentIndex = 0;
  String? _fileName;
  Color _currentColor = Colors.white;
  double _currentThickness = 2.0;
  bool _isErasing = false;
  List<List<List<Stroke>>> _undoHistory = [];
  List<List<List<Stroke>>> _redoHistory = [];

  // Current stroke being drawn
  Stroke? _currentStroke;

  List<Stroke> get currentPage => _pages[_currentIndex];

  int get currentIndex => _currentIndex;

  int get totalPages => _pages.length;

  String? get fileName => _fileName;

  List<List<Stroke>> get pages => _pages;

  Color get currentColor => _currentColor;

  double get currentThickness => _currentThickness;

  bool get isErasing => _isErasing;

  bool get canUndo => _undoHistory.isNotEmpty;

  bool get canRedo => _redoHistory.isNotEmpty;

  void setFileName(String name) {
    _fileName = name;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    _isErasing = false;
    notifyListeners();
  }

  void setThickness(double thickness) {
    _currentThickness = thickness;
    notifyListeners();
  }

  void toggleEraser() {
    _isErasing = !_isErasing;
    notifyListeners();
  }

  void _saveState() {
    _undoHistory.add(List.from(_pages.map((page) => List.from(page))));
    _redoHistory.clear();
  }

  void undo() {
    if (_undoHistory.isEmpty) return;
    
    _redoHistory.add(List.from(_pages.map((page) => List.from(page))));
    _pages = _undoHistory.removeLast();
    notifyListeners();
    _autoSave();
  }

  void redo() {
    if (_redoHistory.isEmpty) return;
    
    _undoHistory.add(List.from(_pages.map((page) => List.from(page))));
    _pages = _redoHistory.removeLast();
    notifyListeners();
    _autoSave();
  }

  void addPoint(Offset point) {
    if (_currentStroke == null) {
      _currentStroke = Stroke(
        [point],
        _currentColor,
        _currentThickness,
        _isErasing,
      );
      _pages[_currentIndex].add(_currentStroke!);
      _saveState();
    } else {
      _currentStroke!.points.add(point);
    }
    notifyListeners();
    _autoSave();
  }

  void endLine() {
    if (_currentStroke != null) {
      _currentStroke!.points.add(null);
      _currentStroke = null;
    }
    notifyListeners();
    _autoSave();
  }

  void addPage(){
    _pages.add([]);
    _currentIndex = _pages.length-1;
    notifyListeners();
    _autoSave();
  }

  void deletePage(){
    if(_pages.length > 1){
      _pages.removeAt(_currentIndex);
    }
    _currentIndex = (_currentIndex-1).clamp(0, _pages.length-1);
    notifyListeners();
    _autoSave();
  }

  void switchPage(int index){
    if(index >= 0 && index < _pages.length) {
      _currentIndex = index;
      notifyListeners();
      _autoSave();
    }
  }

  void loadPages(List<List<Offset?>> oldPages, String fileName) {
    _pages = oldPages.map((page) => [
      Stroke(page, Colors.white, 2.0, false)
    ]).toList();
    _fileName = fileName;
    _currentIndex = 0;
    notifyListeners();
  }

  Future<void> _autoSave() async {
    if (_fileName == null) return;
    
    try {
      await NoteSaver.saveNote(_pages, _fileName!);
      print('Auto-saved note: $_fileName');
    } catch (e) {
      print('Error auto-saving note: $e');
    }
  }
}