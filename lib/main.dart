import 'package:flutter/material.dart';
import 'api_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AppController(),
    );
  }
}

class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  final ApiClient _apiClient = ApiClient('http://localhost:8002');
  bool _isLoggedIn = false;

  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return NotesDashboard(apiClient: _apiClient);
    } else {
      return LoginView(
        apiClient: _apiClient,
        onLoginSuccess: _handleLoginSuccess,
      );
    }
  }
}

class LoginView extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onLoginSuccess;

  const LoginView({
    super.key,
    required this.apiClient,
    required this.onLoginSuccess,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = "";
  bool _isLoading = false;

  void _attemptLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Fields cannot be blank.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });
    bool isSuccess = await widget.apiClient.login(username, password);
    setState(() {
      _isLoading = false;
    });

    if (isSuccess) {
      widget.onLoginSuccess();
    } else {
      setState(() {
        _errorMessage = "Authentication failed.";
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Notes API Login',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _attemptLogin,
                      child: const Text('Login'),
                    ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NotesDashboard extends StatefulWidget {
  final ApiClient apiClient;
  const NotesDashboard({super.key, required this.apiClient});

  @override
  State<NotesDashboard> createState() => _NotesDashboardState();
}

class _NotesDashboardState extends State<NotesDashboard> {
  List<dynamic> _notes = [];
  Map<String, dynamic>? _selectedNote;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _isLoading = true;
    });
    final notes = await widget.apiClient.getNotes();
    setState(() {
      _notes = notes;
      _isLoading = false;

      if (_selectedNote != null && _selectedNote!['id'] != 'NEW') {
        // Keep selected state synced if item still exists
        final currentNoteIndex = notes.indexWhere(
          (n) => n['id'] == _selectedNote!['id'],
        );
        if (currentNoteIndex != -1) {
          _selectedNote = notes[currentNoteIndex] as Map<String, dynamic>;
        } else {
          _clearEditor();
        }
      }
    });
  }

  void _selectNote(Map<String, dynamic> note) {
    setState(() {
      _selectedNote = note;
      _titleController.text = note['title'] ?? '';
      _contentController.text = note['content'] ?? '';
    });
  }

  void _prepareNewNote() {
    setState(() {
      _selectedNote = {
        'id': 'NEW',
        'title': '',
        'content': '',
        'is_completed': false,
      };
      _titleController.clear();
      _contentController.clear();
    });
  }

  void _clearEditor() {
    _selectedNote = null;
    _titleController.clear();
    _contentController.clear();
  }

  void _saveCurrentNote() async {
    if (_selectedNote == null) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title cannot be empty')));
      return;
    }

    setState(() {
      _isSaving = true;
    });
    bool success = false;

    if (_selectedNote!['id'] == 'NEW') {
      success = await widget.apiClient.createNote(title, content);
    } else {
      success = await widget.apiClient.updateNote(
        _selectedNote!['id'],
        title,
        content,
      );
    }

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note saved!')));
      _clearEditor();
      _refreshNotes();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving note.')));
    }
  }

  // Execution: Completion Modifier
  void _toggleCurrentCompletion() async {
    if (_selectedNote == null || _selectedNote!['id'] == 'NEW') return;

    final currentStatus = _selectedNote!['is_completed'] == true;
    final targetStatus = !currentStatus;

    bool success = await widget.apiClient.toggleNoteCompletion(
      _selectedNote!['id'],
      targetStatus,
    );
    if (success) {
      _refreshNotes(); // Pull fresh database row array states
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update task completion.')),
      );
    }
  }

  // Execution: Destruction Destructor
  void _deleteCurrentNote() async {
    if (_selectedNote == null || _selectedNote!['id'] == 'NEW') return;

    setState(() {
      _isLoading = true;
    });
    bool success = await widget.apiClient.deleteNote(_selectedNote!['id']);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note deleted permanent.')));
      _clearEditor();
      _refreshNotes();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database deletion failed.')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExistingNote =
        _selectedNote != null && _selectedNote!['id'] != 'NEW';
    final isCompleted =
        _selectedNote != null && _selectedNote!['is_completed'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Manager'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Note',
            onPressed: _prepareNewNote,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshNotes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // MASTER COLUMN
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: _notes.isEmpty
                        ? const Center(child: Text('No notes found.'))
                        : ListView.builder(
                            itemCount: _notes.length,
                            itemBuilder: (context, index) {
                              final note =
                                  _notes[index] as Map<String, dynamic>;
                              final isSelected =
                                  _selectedNote != null &&
                                  _selectedNote!['id'] == note['id'];
                              final isNoteDone = note['is_completed'] == true;

                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Colors.blue.shade50,
                                leading: Icon(
                                  isNoteDone
                                      ? Icons.check_circle
                                      : Icons.description,
                                  color: isNoteDone
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                title: Text(
                                  note['title'] ?? 'Untitled',
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    decoration: isNoteDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  note['content'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectNote(note),
                              );
                            },
                          ),
                  ),
                ),

                // DETAIL COLUMN
                Expanded(
                  flex: 2,
                  child: _selectedNote == null
                      ? const Center(
                          child: Text(
                            'Select a note or click + to create one.',
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Task Status Toggle Button (Existing Notes Only)
                                  if (isExistingNote) ...[
                                    IconButton(
                                      icon: Icon(
                                        isCompleted
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        color: isCompleted
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      tooltip: isCompleted
                                          ? 'Mark Incomplete'
                                          : 'Mark Completed',
                                      onPressed: _toggleCurrentCompletion,
                                    ),
                                  ],
                                  Expanded(
                                    child: TextField(
                                      controller: _titleController,
                                      decoration: const InputDecoration(
                                        labelText: 'Title',
                                        border: UnderlineInputBorder(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _isSaving
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton.icon(
                                          onPressed: _saveCurrentNote,
                                          icon: const Icon(Icons.save),
                                          label: const Text('Save'),
                                        ),
                                  const SizedBox(width: 8),
                                  // Trash Deletion Button (Existing Notes Only)
                                  if (isExistingNote) ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete Note',
                                      onPressed: _deleteCurrentNote,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: TextField(
                                  controller: _contentController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: const InputDecoration(
                                    labelText: 'Content',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
