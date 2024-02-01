// notes_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Corrected import statement

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _getNotesFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Add new note'),
                    onSubmitted: (text) {
                      _addNote();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _addNote();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                var note = notes[index];
                return ListTile(
                  title: Text(note['text']),
                  subtitle: Text(note['createdAt'].toString()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editNoteDialog(index);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _confirmDeleteDialog(index);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getNotesFromFirestore() async {
    try {
      // Retrieve notes from Firestore based on the current user's UID
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();

      setState(() {
        // Update the 'notes' list with the retrieved documents
        notes = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    } catch (e) {
      // Handle any errors during the retrieval process
      print('Error retrieving notes: $e');
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    // Navigate back to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _addNote() {
    String text = _noteController.text;
    if (text.isNotEmpty) {
      setState(() {
        notes.add({
          'text': text,
          'createdAt': DateTime.now(),
          'userId': FirebaseAuth.instance.currentUser?.uid ?? '', // Use the current user's UID
        });
        _noteController.clear();
        _saveNoteToFirestore(text);
      });
    }
  }

  void _saveNoteToFirestore(String text) {
    // Use Firestore to save the note
    FirebaseFirestore.instance.collection('notes').add({
      'text': text,
      'createdAt': DateTime.now(),
      'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
    });
  }

  void _editNoteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: TextField(
            controller: TextEditingController(text: notes[index]['text']),
            onChanged: (text) {
              // Handle edited text
              notes[index]['text'] = text;
            },
            onSubmitted: (_) {
              _saveNoteToFirestore(notes[index]['text']);
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Handle save/edit logic
                _saveNoteToFirestore(notes[index]['text']);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteNote(index);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
      // Also delete the note from Firestore
      _deleteNoteFromFirestore(index);
    });
  }

  void _deleteNoteFromFirestore(int index) {
    String noteId = notes[index]['id']; // Assuming you have an 'id' field in the note
    if (noteId != null) {
      FirebaseFirestore.instance.collection('notes').doc(noteId).delete();
    }
  }
}
