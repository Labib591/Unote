import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:unote/Models/drawing_painter.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:unote/Models/toolbar_fucntions.dart';
import 'package:unote/widgets/custom_toolbar.dart';

class editorScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("MY NOTE", style: TextStyle(
            color: Colors.white
          ),),
          actions: [
            IconButton(
              icon: Icon(Icons.add,
              color: Colors.white,),
              onPressed: () => context.read<PageManager>().addPage(),
            ),
            IconButton(
              icon: Icon(Icons.delete,
              color: Colors.white,),
              onPressed: () => context.read<PageManager>().deletePage(),
            ),
            IconButton(
              icon: Icon(Icons.minimize_rounded,
                color: Colors.white,),
              onPressed: () => context.read<ToolbarFunctions>().erase(),
            ),
          ],
        ),
        body: Consumer<PageManager>(
              builder: (context, PageManager , child) {
                return DrawingCanvas(PageManager.currentPage);
              },
            ),
        bottomNavigationBar: Consumer<PageManager >(
          builder: (context, PageManager , child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(PageManager.totalPages, (index) {
                return GestureDetector(
                  onTap: () => PageManager.switchPage(index),
                  child: Container(
                    margin: EdgeInsets.all(4),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PageManager.currentIndex == index ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text("Page ${index + 1}"),
                  ),
                );
              }),
            );
          },
        ),
    );
  }
}