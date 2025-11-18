import 'package:flutter/foundation.dart';
import '../models/contact_note.dart';
import '../services/database_service.dart';

class ContactNotesProvider with ChangeNotifier {
  List<ContactNote> _notes = [];
  bool _isLoading = false;

  List<ContactNote> get notes => _notes;
  bool get isLoading => _isLoading;

  ContactNotesProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await DatabaseService.instance.getAllNotes();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveNote(ContactNote note) async {
    try {
      final savedNote = await DatabaseService.instance.upsertNote(note);

      // Update local list
      final index = _notes.indexWhere((n) => n.id == savedNote.id);
      if (index != -1) {
        _notes[index] = savedNote;
      } else {
        _notes.insert(0, savedNote);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving note: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await DatabaseService.instance.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  Future<List<ContactNote>> searchNotes(String query) async {
    if (query.isEmpty) {
      return _notes;
    }

    try {
      return await DatabaseService.instance.searchNotes(query);
    } catch (e) {
      debugPrint('Error searching notes: $e');
      return [];
    }
  }

  ContactNote? getNoteByPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return _notes.firstWhere(
      (note) => note.phoneNumber.contains(cleanNumber),
      orElse: () => _notes.first,
    );
  }
}
