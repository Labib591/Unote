import 'package:flutter/cupertino.dart';

class PageManager extends ChangeNotifier{
  List<List<Offset?>> _pages = [[]];
  int _currentIndex = 0;
  List<Offset?> get currentPage => _pages[_currentIndex];

  int get currentIndex => _currentIndex;

  int get totalPages => _pages.length;

  void addPage(){
    _pages.add([]);
    _currentIndex = _pages.length-1;
    notifyListeners();
  }

  void deletePage(){
    if(_pages.length > 1){
      _pages.removeAt(_currentIndex);
    }
    _currentIndex = (_currentIndex-1).clamp(0, _pages.length-1);
    notifyListeners();
  }

  void switchPage(int index){
    if(index >= 0 && index < _pages.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}