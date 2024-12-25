import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:unote/screens/editor_screen.dart';
import 'package:unote/Models/save.dart';
import 'package:provider/provider.dart';
import 'package:unote/Models/page_manager.dart';

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
      final directory = await getExternalStorageDirectory();
      if (directory == null) return;

      final noteDirectory = Directory('${directory.path}/UNotes');
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('My Notes', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              final fileName = 'Note_${DateTime.now().millisecondsSinceEpoch}';
              final pageManager = PageManager();
              pageManager.loadPages([[]], fileName);
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => pageManager,
                    child: editorScreen(),
                  ),
                ),
              ).then((_) => _loadNotes());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotes,
        child: notes.isEmpty
            ? Center(
                child: Text(
                  'No notes yet\nTap + to create one',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<String>(
                    future: _getLastModified(notes[index].path),
                    builder: (context, dateSnapshot) {
                      return Card(
                        color: Colors.grey[900],
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          onTap: () async {
                            try {
                              final fileName = _getFileName(notes[index].path);
                              print('Loading note: $fileName');
                              
                              final pages = await NoteSaver.loadNote(fileName);
                              print('Loaded pages: ${pages.length}');
                              
                              if (!mounted) return;
                              
                              final pageManager = PageManager();
                              pageManager.loadPages(pages, fileName);
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChangeNotifierProvider(
                                    create: (_) => pageManager,
                                    child: editorScreen(),
                                  ),
                                ),
                              ).then((_) => _loadNotes());
                            } catch (e) {
                              print('Error in onTap: $e');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error loading note: $e')),
                              );
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Row(
                              children: [
                                // Preview
                                FutureBuilder<File?>(
                                  future: _getPreviewFile(_getFileName(notes[index].path)),
                                  builder: (context, previewSnapshot) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[800]!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: previewSnapshot.hasData && previewSnapshot.data != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.file(
                                                previewSnapshot.data!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(Icons.note, color: Colors.grey),
                                    );
                                  },
                                ),
                                SizedBox(width: 16),
                                // Note details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getFileName(notes[index].path),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Last modified: ${dateSnapshot.data ?? 'Loading...'}',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
} 