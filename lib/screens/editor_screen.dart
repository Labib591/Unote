import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:unote/Models/drawing_painter.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:unote/Models/save.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';

class EditorScreen extends StatefulWidget {
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _autoSaveTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      final pageManager = context.read<PageManager>();
      if (pageManager.fileName != null) {
        try {
          await NoteSaver.saveNote(pageManager.fileName!, pageManager.pages);
          print('Auto-saved: ${pageManager.fileName}'); // Debug print
        } catch (e) {
          print('Auto-save error: $e'); // Debug print
        }
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    final pageManager = context.read<PageManager>();
    if (pageManager.fileName != null) {
      NoteSaver.saveNote(pageManager.fileName!, pageManager.pages);
      print('Final save on dispose: ${pageManager.fileName}'); // Debug print
    }
    super.dispose();
  }

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
                  final fileName = fileNameController.text;
                  await NoteSaver.saveNote(
                    fileName,
                    context.read<PageManager>().pages,
                  );
                  context.read<PageManager>().setFileName(fileName);
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
    final pageManager = context.watch<PageManager>();

    return WillPopScope(
      onWillPop: () async {
        if (pageManager.fileName != null) {
          try {
            await NoteSaver.saveNote(pageManager.fileName!, pageManager.pages);
            print('Saved on exit: ${pageManager.fileName}'); // Debug print
          } catch (e) {
            print('Save on exit error: $e'); // Debug print
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(pageManager.fileName ?? 'Untitled',
          style: TextStyle(color: Colors.white),),
          actions: [
            PopupMenuButton<int>(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page ${pageManager.currentIndex + 1}/${pageManager.pageCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                  ],
                ),
              ),
              itemBuilder: (context) => List.generate(
                pageManager.pageCount,
                (index) => PopupMenuItem(
                  value: index,
                  child: Text(
                    'Page ${index + 1}',
                    style: TextStyle(
                      color: index == pageManager.currentIndex ? Colors.purple : Colors.white,
                      fontWeight: index == pageManager.currentIndex ? 
                        FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              onSelected: (index) {
                pageManager.goToPage(index);
              },
              color: Colors.grey.shade900,
            ),
          ],
        ),
        body: Stack(
          children: [
            DrawingCanvas(
              currentPage: pageManager.currentPage,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pen style and color
                        PopupMenuButton<Color>(
                          icon: Icon(Icons.brush, color: Colors.white),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              enabled: false,
                              child: Text('Colors',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ),
                            PopupMenuItem(
                              enabled: false,
                              child: Container(
                                width: 200,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ...Colors.primaries.map((color) => InkWell(
                                      onTap: () {
                                        context.read<PageManager>().setColor(color);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                                        ),
                                      ),
                                    )).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          color: Colors.grey.shade900,
                        ),
                        // Pen thickness
                        IconButton(
                          icon: Icon(Icons.line_weight, color: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey.shade900,
                                title: Text('Pen Thickness', style: TextStyle(color: Colors.white)),
                                content: StatefulBuilder(
                                  builder: (context, setState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Slider(
                                          value: pageManager.currentThickness,
                                          min: 1.0,
                                          max: 20.0,
                                          divisions: 19,
                                          label: pageManager.currentThickness.round().toString(),
                                          onChanged: (value) {
                                            setState(() {
                                              pageManager.setThickness(value);
                                            });
                                          },
                                        ),
                                        SizedBox(height: 20),
                                        Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 100,
                                              height: pageManager.currentThickness,
                                              color: pageManager.currentColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('OK'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Eraser
                        IconButton(
                          icon: Icon(Icons.close,
                            color: pageManager.isErasing ? Colors.red : Colors.white),
                          onPressed: () => pageManager.toggleEraser(),
                        ),
                        // Undo
                        IconButton(
                          icon: Icon(Icons.undo,
                            color: pageManager.canUndo ? Colors.white : Colors.grey),
                          onPressed: pageManager.canUndo ? () => pageManager.undo() : null,
                        ),
                        // Redo
                        IconButton(
                          icon: Icon(Icons.redo,
                            color: pageManager.canRedo ? Colors.white : Colors.grey),
                          onPressed: pageManager.canRedo ? () => pageManager.redo() : null,
                        ),
                        // Delete page
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey.shade900,
                                title: Text('Delete Page',
                                  style: TextStyle(color: Colors.white)),
                                content: Text('Are you sure you want to delete this page?',
                                  style: TextStyle(color: Colors.white)),
                                actions: [
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      pageManager.deletePage();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Background color
                        PopupMenuButton<Color>(
                          icon: Icon(Icons.format_color_fill, color: Colors.white),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              enabled: false,
                              child: Text('Background Color',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ),
                            PopupMenuItem(
                              enabled: false,
                              child: Container(
                                width: 200,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ...Colors.primaries.map((color) => InkWell(
                                      onTap: () {
                                        context.read<PageManager>().setBackgroundColor(color);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                                        ),
                                      ),
                                    )).toList(),
                                    ...[ Colors.black, Colors.white ].map((color) => InkWell(
                                      onTap: () {
                                        context.read<PageManager>().setBackgroundColor(color);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                        ),
                                      ),
                                    )).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          color: Colors.grey.shade900,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Previous page
                        IconButton(
                          icon: Icon(Icons.arrow_left,
                            color: pageManager.canGoToPreviousPage ? Colors.white : Colors.grey),
                          onPressed: pageManager.canGoToPreviousPage ?
                            () => pageManager.previousPage() : null,
                        ),
                        // Add new page
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.white),
                          onPressed: () => pageManager.addPage(),
                        ),
                        // Next page
                        IconButton(
                          icon: Icon(Icons.arrow_right,
                            color: pageManager.canGoToNextPage ? Colors.white : Colors.grey),
                          onPressed: pageManager.canGoToNextPage ?
                            () => pageManager.nextPage() : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}