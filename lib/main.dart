import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NotesProvider(
      child: MaterialApp(
        title: 'Aplikasi Catatan',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const NotesListScreen(),
      ),
    );
  }
}

// Model untuk Catatan
class Note {
  final String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Provider manual untuk mengelola daftar catatan (tanpa package provider)
class NotesProvider extends InheritedNotifier<NotesNotifier> {
  NotesProvider({super.key, required Widget child})
      : super(child: child, notifier: NotesNotifier());

  static NotesNotifier of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<NotesProvider>();
    return provider!.notifier!;
  }

  static NotesNotifier? maybeOf(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<NotesProvider>();
    return provider?.notifier;
  }
}

class NotesNotifier extends ChangeNotifier {
  final List<Note> _notes = [];
  final Map<String, Map<String, String>> _drafts = {}; // Menyimpan draf catatan

  List<Note> get notes => List.unmodifiable(_notes);
  Map<String, Map<String, String>> get drafts => Map.unmodifiable(_drafts);

  void addNote(Note note) {
    _notes.add(note);
    notifyListeners();
  }

  void updateNote(String id, String title, String content) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void deleteNote(String id) {
    _notes.removeWhere((note) => note.id == id);
    // Hapus juga draf jika ada
    _drafts.remove(id);
    notifyListeners();
  }

  Note? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  // Menyimpan draf catatan
  void saveDraft(String noteId, String title, String content) {
    _drafts[noteId] = {
      'title': title,
      'content': content,
    };
    notifyListeners();
  }

  // Mengambil draf catatan
  Map<String, String>? getDraft(String noteId) {
    return _drafts[noteId];
  }

  // Menghapus draf setelah catatan disimpan
  void removeDraft(String noteId) {
    _drafts.remove(noteId);
    notifyListeners();
  }
}

// Halaman utama untuk menampilkan daftar catatan
class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Saya'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: NotesProvider.of(context),
        builder: (context, child) {
          final notesProvider = NotesProvider.of(context);
          
          if (notesProvider.notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada catatan',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap tombol + untuk menambah catatan baru',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notesProvider.notes.length,
            itemBuilder: (context, index) {
              final note = notesProvider.notes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(
                    note.title.isEmpty ? 'Tanpa Judul' : note.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.content.isNotEmpty)
                        Text(
                          note.content.length > 100
                              ? '${note.content.substring(0, 100)}...'
                              : note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Dibuat: ${_formatDate(note.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditNoteScreen(noteId: note.id),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, note);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditNoteScreen(noteId: note.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditNoteScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Apakah Anda yakin ingin menghapus catatan "${note.title.isEmpty ? 'Tanpa Judul' : note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              NotesProvider.of(context).deleteNote(note.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Catatan berhasil dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Halaman untuk menambah atau mengedit catatan
class AddEditNoteScreen extends StatefulWidget {
  final String? noteId;

  const AddEditNoteScreen({super.key, this.noteId});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen>
    with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;
  Note? _currentNote;

  @override
  void initState() {
    super.initState();
    
    // Menambahkan observer untuk lifecycle
    WidgetsBinding.instance.addObserver(this);
    
    // Inisialisasi TextEditingController
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    
    _isEditing = widget.noteId != null;
    
    if (_isEditing) {
      // Mengisi TextEditingController saat mengedit catatan yang ada
      final notesProvider = NotesProvider.of(context);
      _currentNote = notesProvider.getNoteById(widget.noteId!);
      
      if (_currentNote != null) {
        _titleController.text = _currentNote!.title;
        _contentController.text = _currentNote!.content;
      }
      
      // Cek apakah ada draf yang tersimpan
      final draft = notesProvider.getDraft(widget.noteId!);
      if (draft != null) {
        _titleController.text = draft['title'] ?? '';
        _contentController.text = draft['content'] ?? '';
        
        // Tampilkan snackbar bahwa draf dimuat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Draf catatan dimuat'),
              backgroundColor: Colors.orange,
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    // Menghapus observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Dispose TextEditingController dengan benar
    _titleController.dispose();
    _contentController.dispose();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Menyimpan draf saat aplikasi paused
    if (state == AppLifecycleState.paused) {
      _saveDraft();
    }
  }

  void _saveDraft() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    // Hanya simpan draf jika ada perubahan
    if (title.isNotEmpty || content.isNotEmpty) {
      final noteId = widget.noteId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final notesProvider = NotesProvider.of(context);
      
      // Cek apakah konten berbeda dari aslinya (untuk editing)
      if (_isEditing && _currentNote != null) {
        if (title != _currentNote!.title || content != _currentNote!.content) {
          notesProvider.saveDraft(noteId, title, content);
        }
      } else if (!_isEditing) {
        // Untuk catatan baru, selalu simpan draf
        notesProvider.saveDraft(noteId, title, content);
      }
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul atau isi catatan tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final notesProvider = NotesProvider.of(context);
    
    if (_isEditing) {
      // Update catatan yang ada
      notesProvider.updateNote(widget.noteId!, title, content);
      // Hapus draf setelah disimpan
      notesProvider.removeDraft(widget.noteId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil diperbarui')),
      );
    } else {
      // Tambah catatan baru
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      notesProvider.addNote(newNote);
      // Hapus draf setelah disimpann
      notesProvider.removeDraft(newNote.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil ditambahkan')),
      );
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Catatan' : 'Tambah Catatan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _saveNote,
            icon: const Icon(Icons.save),
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Catatan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 200),
                    child: Icon(Icons.description),
                  ),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveNote,
                    icon: const Icon(Icons.save),
                    label: Text(_isEditing ? 'Perbarui' : 'Simpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Batal'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}