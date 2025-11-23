import 'package:flutter/foundation.dart';
import '../models/contact_note.dart';
import '../services/database_service.dart';
import '../utils/phone_utils.dart';

class ContactNotesProvider with ChangeNotifier {
  List<ContactNote> _notes = [];
  bool _isLoading = false;

  List<ContactNote> get notes => _notes;
  bool get isLoading => _isLoading;

  ContactNotesProvider() {
    // Загружаем заметки асинхронно без блокировки конструктора
    _loadNotesAsync();
  }

  // Вспомогательный метод для асинхронной загрузки без await в конструкторе
  void _loadNotesAsync() {
    Future.microtask(() => loadNotes());
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📝 Загрузка заметок из БД...');
      _notes = await DatabaseService.instance.getAllNotes().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ Таймаут загрузки заметок');
          return [];
        },
      );
      debugPrint('✅ Загружено ${_notes.length} заметок');
    } catch (e) {
      debugPrint('❌ Error loading notes: $e');
      _notes = []; // Возвращаем пустой список при ошибке
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
    if (_notes.isEmpty) return null;

    try {
      return _notes.firstWhere(
        (note) => PhoneUtils.areEqual(note.phoneNumber, phoneNumber),
      );
    } catch (e) {
      debugPrint('Note not found for number: $phoneNumber');
      return null;
    }
  }
}
