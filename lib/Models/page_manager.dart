import 'package:flutter/material.dart';
import 'package:unote/Models/save.dart';
import 'dart:math';

class Stroke {
  List<Offset?> points;
  final Color color;
  final double thickness;
  final bool isEraser;

  Stroke(this.points, this.color, this.thickness, this.isEraser);
}

enum ShapeType {
  none,
  line,
  rectangle,
  circle,
  triangle,
  arrow
}

enum PenStyle {
  normal,
  dotted,
  dashed,
  double,
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

  double _eraserSize = 20.0;

  // Add selection related fields
  bool _isSelecting = false;
  Rect? _selectionRect;
  List<Stroke>? _copiedStrokes;
  Offset? _selectionStart;
  Offset? _selectionEnd;

  // Add undo/redo stacks
  List<List<Stroke>> _undoStack = [];
  List<List<Stroke>> _redoStack = [];

  // Add shape-related fields
  ShapeType _currentShape = ShapeType.none;
  Offset? _shapeStart;
  Offset? _shapeEnd;

  // Add pen style field
  PenStyle _currentPenStyle = PenStyle.normal;

  Color _backgroundColor = Colors.black;

  List<Stroke> get currentPage {
    print("Current page has ${_pages[_currentIndex].length} strokes"); // Debug print
    return _pages[_currentIndex];
  }

  int get currentIndex => _currentIndex;

  int get totalPages => _pages.length;

  String? get fileName => _fileName;

  List<List<Stroke>> get pages => _pages;

  Color get currentColor => _currentColor;

  double get currentThickness => _currentThickness;

  bool get isErasing => _isErasing;

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  double get eraserSize => _eraserSize;

  bool get isSelecting => _isSelecting;

  Rect? get selectionRect => _selectionRect;

  List<Stroke>? get copiedStrokes => _copiedStrokes;

  ShapeType get currentShape => _currentShape;

  bool get isDrawingShape => _currentShape != ShapeType.none;

  Offset? get shapeStart => _shapeStart;

  Offset? get shapeEnd => _shapeEnd;

  PenStyle get currentPenStyle => _currentPenStyle;

  bool get canGoToPreviousPage => _currentIndex > 0;
  bool get canGoToNextPage => _currentIndex < _pages.length - 1;

  Color get backgroundColor => _backgroundColor;

  int get pageCount => _pages.length;

  void previousPage() {
    if (canGoToPreviousPage) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void nextPage() {
    if (canGoToNextPage) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void addPage() {
    _pages.add([]);
    _currentIndex = _pages.length - 1;
    notifyListeners();
  }

  void deletePage() {
    if (_pages.length > 1) {
      _pages.removeAt(_currentIndex);
      if (_currentIndex >= _pages.length) {
        _currentIndex = _pages.length - 1;
      }
      notifyListeners();
    }
  }

  void setThickness(double thickness) {
    _currentThickness = thickness;
    notifyListeners();
  }

  void setFileName(String name) {
    _fileName = name;
    print('Filename set to: $_fileName'); // Debug print
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    _isErasing = false;
    notifyListeners();
  }

  void setEraserSize(double size) {
    _eraserSize = size;
    _currentThickness = size;
    notifyListeners();
  }

  void toggleEraser() {
    _isErasing = !_isErasing;
    _currentThickness = _isErasing ? _eraserSize : 2.0;
    notifyListeners();
  }

  void _saveState() {
    _undoHistory.add(List.from(_pages.map((page) => 
      List.from(page.map((stroke) => Stroke(
        List.from(stroke.points),
        stroke.color,
        stroke.thickness,
        stroke.isEraser,
      )))
    )));
    _redoHistory.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    
    // Save current state to redo stack
    _redoStack.add(List.from(_pages[_currentIndex]));
    
    // Restore previous state
    _pages[_currentIndex] = _undoStack.removeLast();
    _currentStroke = null;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    
    // Save current state to undo stack
    _undoStack.add(List.from(_pages[_currentIndex]));
    
    // Restore next state
    _pages[_currentIndex] = _redoStack.removeLast();
    _currentStroke = null;
    notifyListeners();
  }

  void addPoint(Offset point) {
    print("Adding point: $point"); // Debug print
    if (_currentStroke == null) {
      print("Creating new stroke"); // Debug print
      // Save current state for undo when starting new stroke
      _undoStack.add(List.from(_pages[_currentIndex]));
      _redoStack.clear(); // Clear redo stack when new changes are made
      
      _currentStroke = Stroke(
        [point],
        _currentColor,
        _currentThickness,
        _isErasing,
      );
      _pages[_currentIndex].add(_currentStroke!);
    } else {
      print("Adding to existing stroke"); // Debug print
      _currentStroke!.points.add(point);
    }
    notifyListeners();
    _autoSave();
  }

  void endLine() {
    print("Ending line"); // Debug print
    if (_currentStroke != null) {
      _currentStroke!.points.add(null);
      _currentStroke = null;
    }
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

  void loadPages(List<List<Stroke>> pages, String fileName) {
    if (pages.isEmpty) {
      _pages = [[]];
    } else {
      _pages = pages;
    }
    _fileName = fileName;
    _currentIndex = 0;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  Future<void> _autoSave() async {
    if (_fileName == null) return;
    
    try {
      await NoteSaver.saveNote(_fileName!, _pages);
      print('Auto-saved note: $_fileName');
    } catch (e) {
      print('Error auto-saving note: $e');
    }
  }

  void setPenStyle(PenStyle style) {
    _currentPenStyle = style;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void goToPage(int index) {
    if (index >= 0 && index < _pages.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> saveToFile() async {
    if (_fileName != null) {
      await NoteSaver.saveNote(_fileName!, _pages);
    }
  }

  Future<void> loadFromFile(String fileName) async {
    final pages = await NoteSaver.loadNote(fileName);
    _pages = pages;  // pages is already List<List<Stroke>>
    _backgroundColor = Colors.black;  // Use default background color
    _fileName = fileName;
    notifyListeners();
  }
}