import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact_note.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('context_keeper.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contact_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id TEXT NOT NULL,
        contact_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        notes TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Index for faster phone number lookups
    await db.execute('''
      CREATE INDEX idx_phone_number ON contact_notes(phone_number)
    ''');
  }

  // Create or update note
  Future<ContactNote> upsertNote(ContactNote note) async {
    final db = await database;

    if (note.id != null) {
      // Update existing note
      await db.update(
        'contact_notes',
        note.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
      return note.copyWith(updatedAt: DateTime.now());
    } else {
      // Insert new note
      final id = await db.insert('contact_notes', note.toMap());
      return note.copyWith(id: id);
    }
  }

  // Get note by phone number (improved with better normalization)
  Future<ContactNote?> getNoteByPhoneNumber(String phoneNumber) async {
    final db = await database;

    // Improved phone number matching
    // Try multiple variations of the number
    final variations = _generatePhoneVariations(phoneNumber);

    for (final variation in variations) {
      final results = await db.query(
        'contact_notes',
        where: 'phone_number LIKE ?',
        whereArgs: ['%$variation%'],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return ContactNote.fromMap(results.first);
      }
    }

    return null;
  }

  // Generate phone number variations for better matching
  List<String> _generatePhoneVariations(String phoneNumber) {
    final variations = <String>[];

    // Clean: only digits and +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    variations.add(cleaned);

    // Only digits
    String onlyDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    variations.add(onlyDigits);

    // Last 10 digits
    if (onlyDigits.length >= 10) {
      variations.add(onlyDigits.substring(onlyDigits.length - 10));
    }

    // Last 7 digits
    if (onlyDigits.length >= 7) {
      variations.add(onlyDigits.substring(onlyDigits.length - 7));
    }

    return variations;
  }

  // Get all notes
  Future<List<ContactNote>> getAllNotes() async {
    final db = await database;
    final results = await db.query(
      'contact_notes',
      orderBy: 'updated_at DESC',
    );

    return results.map((map) => ContactNote.fromMap(map)).toList();
  }

  // Delete note
  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete(
      'contact_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search notes
  Future<List<ContactNote>> searchNotes(String query) async {
    final db = await database;
    final results = await db.query(
      'contact_notes',
      where: 'contact_name LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );

    return results.map((map) => ContactNote.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
