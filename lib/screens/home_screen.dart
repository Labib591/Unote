import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:unote/screens/editor_screen.dart';
import 'package:unote/Models/save.dart';
import 'package:provider/provider.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:path/path.dart' as path;
import 'package:unote/Models/drawing_canvas.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('UNote'),
      ),
      body: FutureBuilder<List<String>>(
        future: NoteSaver.listNotes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final files = snapshot.data!;
          return ListView.builder(
            itemCount: files.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text('New Note', style: TextStyle(color: Colors.white)),
                  leading: Icon(Icons.add, color: Colors.white),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        final controller = TextEditingController();
                        return AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: Text('New Note', style: TextStyle(color: Colors.white)),
                          content: TextField(
                            controller: controller,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter note name',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                            TextButton(
                              child: Text('Create'),
                              onPressed: () async {
                                if (controller.text.isNotEmpty) {
                                  final pageManager = PageManager();
                                  pageManager.setFileName(controller.text);
                                  Navigator.pop(dialogContext);
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChangeNotifierProvider.value(
                                        value: pageManager,
                                        child: EditorScreen(),
                                      ),
                                    ),
                                  );
                                  // Refresh the list when returning from editor
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              }

              final fileName = files[index - 1];
              return ListTile(
                title: Text(fileName, style: TextStyle(color: Colors.grey[900])),
                leading: Container(
                  width: 40,
                  height: 40,
                  child: FutureBuilder<List<List<Stroke>>>(
                    future: NoteSaver.loadNote(fileName),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CustomPaint(
                            painter: DrawingPainter(
                              snapshot.data![0],
                              currentColor: Colors.grey,
                              currentThickness: 2.0,
                              currentShape: ShapeType.none,
                              backgroundColor: Colors.black,
                            ),
                          ),
                        );
                      }
                      return Icon(Icons.note, color: Colors.red);
                    },
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: Text('Delete Note', style: TextStyle(color: Colors.white)),
                        content: Text(
                          'Are you sure you want to delete this note?',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              await NoteSaver.deleteNote(fileName);
                              Navigator.pop(context);
                              // Refresh the screen
                              if (context.mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onTap: () async {
                  final pages = await NoteSaver.loadNote(fileName);
                  final pageManager = PageManager();
                  pageManager.loadPages(pages, fileName);
                  if (!context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: pageManager,
                        child: EditorScreen(),
                      ),
                    ),
                  );
                  // Refresh the list when returning from editor
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
} 