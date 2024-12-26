import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:unote/screens/editor_screen.dart';
import 'package:unote/Models/save.dart';
import 'package:provider/provider.dart';
import 'package:unote/Models/page_manager.dart';
import 'package:path/path.dart' as path;
import 'package:unote/Models/drawing_painter.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FileSystemEntity> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final noteDirectory = Directory(await NoteSaver.getNotesDirectory());
      if (!await noteDirectory.exists()) {
        await noteDirectory.create(recursive: true);
      }

      final files = await noteDirectory.list().toList();
      setState(() {
        notes = files.where((file) => file.path.endsWith('.unote')).toList();
      });
    } catch (e) {
      print('Error loading notes: $e');
    }
  }

  String _getFileName(String path) {
    return path.split('/').last.replaceAll('.unote', '');
  }

  Future<String> _getLastModified(String path) async {
    final file = File(path);
    final modified = await file.lastModified();
    return '${modified.day}/${modified.month}/${modified.year}';
  }

  Future<File?> _getPreviewFile(String fileName) async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) return null;

    final previewFile = File('${directory.path}/UNotes/previews/$fileName.png');
    if (await previewFile.exists()) {
      return previewFile;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              TextEditingController nameController = TextEditingController();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('New Note'),
                  content: TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter note name',
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text('Create'),
                      onPressed: () {
                        final name = nameController.text;
                        if (name.isNotEmpty) {
                          final fileName = name.replaceAll(RegExp(r'[^\w\s-]'), '');
                          final pageManager = PageManager();
                          pageManager.loadPages([[]], fileName);
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider(
                                create: (_) => pageManager,
                                child: editorScreen(),
                              ),
                            ),
                          ).then((_) => _loadNotes());
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final fileName = path.basenameWithoutExtension(notes[index].path);
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: FutureBuilder<List<List<Stroke>>>(
                    future: NoteSaver.loadNote(fileName),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: CustomPaint(
                              painter: DrawingPainter(
                                snapshot.data![0],
                                currentShape: ShapeType.none,
                                currentColor: Colors.white,
                                currentThickness: 2.0,
                              ),
                            ),
                          ),
                        );
                      }
                      return Center(child: Icon(Icons.note, color: Colors.grey));
                    },
                  ),
                ),
              ),
              title: Text(fileName, style: TextStyle(color: Colors.white)),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey.shade900,
                      title: Text('Delete Note', style: TextStyle(color: Colors.white)),
                      content: Text('Are you sure you want to delete "$fileName"?',
                          style: TextStyle(color: Colors.white)),
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
                            _loadNotes();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              onTap: () async {
                try {
                  final pages = await NoteSaver.loadNote(fileName);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) {
                          final pageManager = PageManager();
                          pageManager.loadPages(pages, fileName);
                          return pageManager;
                        },
                        child: editorScreen(),
                      ),
                    ),
                  ).then((_) => _loadNotes());
                } catch (e) {
                  print('Error loading note: $e');
                }
              },
            );
          },
        ),
      ),
    );
  }
} 