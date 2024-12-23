import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:unote/Models/drawing_painter.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:unote/Models/save.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class editorScreen extends StatelessWidget{
  Future<bool> _requestPermission() async {
    try {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  void _showSaveDialog(BuildContext context) async {
    // Check permission before showing dialog
    bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage permission is required'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    // Show dialog only if we have permission
    if (!context.mounted) return;
    
    final TextEditingController fileNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Save Note'),
          content: TextField(
            controller: fileNameController,
            decoration: InputDecoration(
              hintText: 'Enter file name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (fileNameController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Please enter a file name')),
                  );
                  return;
                }

                try {
                  await NoteSaver.saveNote(
                    context.read<PageManager>().pages,
                    fileNameController.text,
                  );
                  Navigator.pop(dialogContext);
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Note saved successfully!')),
                  );
                } catch (e) {
                  print('Error saving note: $e');
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to save note: ${e.toString()}')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

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
              icon: Icon(
                Icons.save,
                color: Colors.white,
              ),
              onPressed: () => _showSaveDialog(context),
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