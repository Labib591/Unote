import 'package:flutter/material.dart';
import 'package:unote/Models/save.dart';
import 'dart:math';

class Stroke {
  List<Offset?> points;
  final Color color;
  final double thickness;
  final bool isEraser;
  final PenStyle penStyle;

  Stroke(this.points, this.color, this.thickness, this.isEraser, this.penStyle);
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
        stroke.penStyle,
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
        _currentPenStyle,
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
      await NoteSaver.saveNote(_pages, _fileName!);
      print('Auto-saved note: $_fileName');
    } catch (e) {
      print('Error auto-saving note: $e');
    }
  }

  void startSelection() {
    _isSelecting = true;
    _selectionRect = null;
    _selectionStart = null;
    _selectionEnd = null;
    notifyListeners();
  }

  void updateSelection(Offset start, Offset end) {
    _selectionStart = start;
    _selectionEnd = end;
    _selectionRect = Rect.fromPoints(start, end);
    notifyListeners();
  }

  void copySelection() {
    if (_selectionRect == null) return;
    _copiedStrokes = _getStrokesInSelection();
    notifyListeners();
  }

  void deleteSelection() {
    if (_selectionRect == null) return;
    _pages[_currentIndex] = _pages[_currentIndex]
        .where((stroke) => !_isStrokeInSelection(stroke))
        .toList();
    _selectionRect = null;
    _isSelecting = false;
    notifyListeners();
    _autoSave();
  }

  void pasteSelection(Offset offset) {
    if (_copiedStrokes == null) return;
    final translatedStrokes = _copiedStrokes!.map((stroke) {
      return Stroke(
        stroke.points.map((p) => p != null 
          ? p + offset 
          : null).toList(),
        stroke.color,
        stroke.thickness,
        stroke.isEraser,
        stroke.penStyle,
      );
    }).toList();
    
    _pages[_currentIndex].addAll(translatedStrokes);
    notifyListeners();
    _autoSave();
  }

  List<Stroke> _getStrokesInSelection() {
    if (_selectionRect == null) return [];
    return _pages[_currentIndex]
        .where((stroke) => _isStrokeInSelection(stroke))
        .toList();
  }

  bool _isStrokeInSelection(Stroke stroke) {
    if (_selectionRect == null) return false;
    return stroke.points
        .where((p) => p != null)
        .any((p) => _selectionRect!.contains(p!));
  }

  void setShapeType(ShapeType shape) {
    print('Setting shape type to: $shape'); // Debug print
    _currentShape = shape;
    notifyListeners();
  }

  void startShape(Offset point) {
    print('Starting shape at: $point'); // Debug print
    _shapeStart = point;
    _shapeEnd = point;
    notifyListeners();
  }

  void updateShape(Offset point) {
    print('Updating shape to: $point'); // Debug print
    _shapeEnd = point;
    notifyListeners();
  }

  void endShape() {
    print('Ending shape. Type: $_currentShape'); // Debug print
    if (_shapeStart != null && _shapeEnd != null) {
      _undoStack.add(List.from(_pages[_currentIndex]));
      _redoStack.clear();
      
      final points = <Offset?>[];
      
      switch (_currentShape) {
        case ShapeType.line:
          points.addAll([_shapeStart!, _shapeEnd!]);
          break;
          
        case ShapeType.rectangle:
          final rect = Rect.fromPoints(_shapeStart!, _shapeEnd!);
          points.addAll([
            rect.topLeft,
            rect.topRight,
            rect.bottomRight,
            rect.bottomLeft,
            rect.topLeft,
          ]);
          break;
          
        case ShapeType.circle:
          final center = Offset(
            (_shapeStart!.dx + _shapeEnd!.dx) / 2,
            (_shapeStart!.dy + _shapeEnd!.dy) / 2,
          );
          final radius = (_shapeEnd! - _shapeStart!).distance / 2;
          for (var i = 0; i <= 360; i += 10) {
            final radians = i * (pi / 180);
            points.add(Offset(
              center.dx + radius * cos(radians),
              center.dy + radius * sin(radians),
            ));
          }
          break;
          
        case ShapeType.triangle:
          points.addAll([
            _shapeStart!,
            _shapeEnd!,
            Offset(_shapeStart!.dx - (_shapeEnd!.dx - _shapeStart!.dx), _shapeEnd!.dy),
            _shapeStart!,
          ]);
          break;
          
        case ShapeType.arrow:
          final delta = _shapeEnd! - _shapeStart!;
          final length = delta.distance;
          final unitVector = delta / length;
          final perpendicular = Offset(-unitVector.dy, unitVector.dx);
          
          points.addAll([
            _shapeStart!,
            _shapeEnd!,
            null,
            _shapeEnd!,
            _shapeEnd! - unitVector * (length * 0.2) + perpendicular * (length * 0.1),
            null,
            _shapeEnd!,
            _shapeEnd! - unitVector * (length * 0.2) - perpendicular * (length * 0.1),
          ]);
          break;
          
        case ShapeType.none:
          break;
      }
      
      if (points.isNotEmpty) {
        _pages[_currentIndex].add(Stroke(
          points,
          _currentColor,
          _currentThickness,
          false,
          _currentPenStyle,
        ));
      }
    }
    
    _shapeStart = null;
    _shapeEnd = null;
    notifyListeners();
  }

  void setPenStyle(PenStyle style) {
    _currentPenStyle = style;
    notifyListeners();
  }
}