import 'package:flutter/cupertino.dart';
import 'package:unote/Models/drawing_canvas.dart';

class ToolbarFunctions extends ChangeNotifier{
  List<Offset?> points = [];


  void erase(){
    if(points.length >1){
      points.removeLast();
      notifyListeners();
    }
  }
}