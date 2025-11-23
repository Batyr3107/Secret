import 'package:flutter_test/flutter_test.dart';
import 'package:context_keeper/models/contact_note.dart';

void main() {
  group('ContactNote', () {
    test('создается корректно с всеми параметрами', () {
      final now = DateTime(2025);
      final note = ContactNote(
        id: 1,
        contactId: 'contact_123',
        contactName: 'Айдос',
        phoneNumber: '+79991234567',
        notes: 'Дочери Рита и Гита, 3 и 1 год',
        createdAt: now,
        updatedAt: now,
      );

      expect(note.id, 1);
      expect(note.contactId, 'contact_123');
      expect(note.contactName, 'Айдос');
      expect(note.phoneNumber, '+79991234567');
      expect(note.notes, 'Дочери Рита и Гита, 3 и 1 год');
      expect(note.createdAt, now);
      expect(note.updatedAt, now);
    });

    test('создается корректно без опциональных параметров', () {
      final note = ContactNote(
        contactId: 'contact_123',
        contactName: 'Айдос',
        phoneNumber: '+79991234567',
        notes: 'Дочери Рита и Гита',
      );

      expect(note.id, isNull);
      expect(note.contactId, 'contact_123');
      expect(note.contactName, 'Айдос');
      expect(note.phoneNumber, '+79991234567');
      expect(note.createdAt, isNotNull);
      expect(note.updatedAt, isNotNull);
    });

    test('toMap() конвертирует правильно', () {
      final now = DateTime(2025);
      final note = ContactNote(
        id: 1,
        contactId: 'contact_123',
        contactName: 'Айдос',
        phoneNumber: '+79991234567',
        notes: 'Дочери Рита и Гита',
        createdAt: now,
        updatedAt: now,
      );

      final map = note.toMap();

      expect(map['id'], 1);
      expect(map['contact_id'], 'contact_123');
      expect(map['contact_name'], 'Айдос');
      expect(map['phone_number'], '+79991234567');
      expect(map['notes'], 'Дочери Рита и Гита');
      expect(map['created_at'], '2025-01-01T00:00:00.000');
      expect(map['updated_at'], '2025-01-01T00:00:00.000');
    });

    test('fromMap() конвертирует правильно', () {
      final map = {
        'id': 1,
        'contact_id': 'contact_123',
        'contact_name': 'Айдос',
        'phone_number': '+79991234567',
        'notes': 'Дочери Рита и Гита',
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-01T00:00:00.000',
      };

      final note = ContactNote.fromMap(map);

      expect(note.id, 1);
      expect(note.contactId, 'contact_123');
      expect(note.contactName, 'Айдос');
      expect(note.phoneNumber, '+79991234567');
      expect(note.notes, 'Дочери Рита и Гита');
      expect(note.createdAt, DateTime(2025));
      expect(note.updatedAt, DateTime(2025));
    });

    test('toMap() и fromMap() являются обратными операциями', () {
      final originalNote = ContactNote(
        id: 1,
        contactId: 'contact_123',
        contactName: 'Айдос',
        phoneNumber: '+79991234567',
        notes: 'Дочери Рита и Гита',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final map = originalNote.toMap();
      final restoredNote = ContactNote.fromMap(map);

      expect(restoredNote.id, originalNote.id);
      expect(restoredNote.contactId, originalNote.contactId);
      expect(restoredNote.contactName, originalNote.contactName);
      expect(restoredNote.phoneNumber, originalNote.phoneNumber);
      expect(restoredNote.notes, originalNote.notes);
      expect(restoredNote.createdAt, originalNote.createdAt);
      expect(restoredNote.updatedAt, originalNote.updatedAt);
    });

    test('copyWith() создает копию с изменениями', () {
      final original = ContactNote(
        id: 1,
        contactId: 'contact_123',
        contactName: 'Айдос',
        phoneNumber: '+79991234567',
        notes: 'Старая заметка',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final updated = original.copyWith(
        notes: 'Новая заметка',
        updatedAt: DateTime(2025, 1, 2),
      );

      expect(updated.id, original.id);
      expect(updated.contactId, original.contactId);
      expect(updated.contactName, original.contactName);
      expect(updated.phoneNumber, original.phoneNumber);
      expect(updated.notes, 'Новая заметка');
      expect(updated.createdAt, original.createdAt);
      expect(updated.updatedAt, DateTime(2025, 1, 2));
    });

    test('copyWith() без параметров создает точную копию', () {
      final original = ContactNote(
        id: 1,
        contactId: 'contact_123',
        contactName: 'Айдос',
        phoneNumber: '+79991234567',
        notes: 'Дочери Рита и Гита',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.contactId, original.contactId);
      expect(copy.contactName, original.contactName);
      expect(copy.phoneNumber, original.phoneNumber);
      expect(copy.notes, original.notes);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
    });

    test('поддерживает кириллицу в заметках', () {
      final note = ContactNote(
        contactId: 'contact_123',
        contactName: 'Марат',
        phoneNumber: '+79991234567',
        notes: 'Коллега по работе, любит кофе латте без сахара',
      );

      final map = note.toMap();
      final restored = ContactNote.fromMap(map);

      expect(restored.notes, 'Коллега по работе, любит кофе латте без сахара');
    });

    test('поддерживает длинные заметки', () {
      final longNote = 'А' * 5000; // 5000 символов
      final note = ContactNote(
        contactId: 'contact_123',
        contactName: 'Тест',
        phoneNumber: '+79991234567',
        notes: longNote,
      );

      final map = note.toMap();
      final restored = ContactNote.fromMap(map);

      expect(restored.notes.length, 5000);
      expect(restored.notes, longNote);
    });

    test('поддерживает спецсимволы в номере телефона', () {
      final note = ContactNote(
        contactId: 'contact_123',
        contactName: 'Айдос',
        phoneNumber: '+7 (999) 123-45-67',
        notes: 'Тест',
      );

      final map = note.toMap();
      final restored = ContactNote.fromMap(map);

      expect(restored.phoneNumber, '+7 (999) 123-45-67');
    });
  });
}
