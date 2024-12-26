import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:unote/Models/drawing_painter.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:unote/Models/save.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
    return WillPopScope(
      onWillPop: () async {
        // Force one last save before leaving
        final pageManager = context.read<PageManager>();
        if (pageManager.fileName != null) {
          try {
            await NoteSaver.saveNote(pageManager.pages, pageManager.fileName!);
            print('Auto-saved note before exit: ${pageManager.fileName}');
          } catch (e) {
            print('Error saving note on exit: $e');
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
            onPressed: () async {
              // Save before going back
              final pageManager = context.read<PageManager>();
              if (pageManager.fileName != null) {
                try {
                  await NoteSaver.saveNote(pageManager.pages, pageManager.fileName!);
                  print('Auto-saved note before navigation: ${pageManager.fileName}');
                } catch (e) {
                  print('Error saving note on navigation: $e');
                }
              }
              Navigator.pop(context);
            },
          ),
          title: Text("MY NOTE", style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () => context.read<PageManager>().addPage(),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: () => context.read<PageManager>().deletePage(),
            ),
          ],
        ),
        body: Consumer<PageManager>(
          builder: (context, pageManager, child) {
            return Stack(
              children: [
                DrawingCanvas(pageManager.currentPage),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Color picker
                        IconButton(
                          icon: Icon(Icons.color_lens, 
                            color: pageManager.currentColor),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Select Color'),
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: pageManager.currentColor,
                                    onColorChanged: (color) {
                                      pageManager.setColor(color);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Thickness slider
                        IconButton(
                          icon: Icon(Icons.line_weight, color: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Pen Thickness'),
                                content: StatefulBuilder(
                                  builder: (context, setState) => Slider(
                                    value: pageManager.currentThickness.clamp(1.0, 10.0),
                                    min: 1.0,
                                    max: 10.0,
                                    divisions: 9,
                                    onChanged: (value) {
                                      pageManager.setThickness(value);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Eraser
                        IconButton(
                          icon: Icon(Icons.auto_fix_high,
                            color: pageManager.isErasing ? Colors.blue : Colors.white),
                          onPressed: () => pageManager.toggleEraser(),
                        ),
                        // Add eraser size slider when eraser is active
                        if (pageManager.isErasing)
                          Container(
                            width: 40,
                            height: 100,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                value: pageManager.eraserSize,
                                min: 5,
                                max: 50,
                                activeColor: Colors.blue,
                                inactiveColor: Colors.grey,
                                onChanged: (value) => pageManager.setEraserSize(value),
                              ),
                            ),
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
                        // Crop
                        IconButton(
                          icon: Icon(Icons.crop_free,
                            color: pageManager.isSelecting ? Colors.blue : Colors.white),
                          onPressed: () => pageManager.startSelection(),
                        ),
                        if (pageManager.isSelecting && pageManager.selectionRect != null)
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.copy, color: Colors.white),
                                onPressed: () => pageManager.copySelection(),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.white),
                                onPressed: () => pageManager.deleteSelection(),
                              ),
                              if (pageManager.copiedStrokes != null)
                                IconButton(
                                  icon: Icon(Icons.paste, color: Colors.white),
                                  onPressed: () => pageManager.pasteSelection(Offset.zero),
                                ),
                            ],
                          ),
                        // Add to your toolbar Column
                        PopupMenuButton<PenStyle>(
                          icon: Icon(Icons.brush, color: Colors.white),
                          onSelected: (PenStyle style) {
                            context.read<PageManager>().setPenStyle(style);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: PenStyle.normal,
                              child: Row(
                                children: [
                                  Icon(Icons.horizontal_rule),
                                  SizedBox(width: 8),
                                  Text('Normal'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: PenStyle.dotted,
                              child: Row(
                                children: [
                                  Text('••••'),
                                  SizedBox(width: 8),
                                  Text('Dotted'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: PenStyle.dashed,
                              child: Row(
                                children: [
                                  Text('- - -'),
                                  SizedBox(width: 8),
                                  Text('Dashed'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: PenStyle.double,
                              child: Row(
                                children: [
                                  Text('═'),
                                  SizedBox(width: 8),
                                  Text('Double'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: Consumer<PageManager>(
          builder: (context, pageManager, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageManager.totalPages, (index) {
                return GestureDetector(
                  onTap: () => pageManager.switchPage(index),
                  child: Container(
                    margin: EdgeInsets.all(4),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: pageManager.currentIndex == index ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text("Page ${index + 1}"),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}