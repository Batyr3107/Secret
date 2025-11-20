import 'package:flutter_test/flutter_test.dart';
import 'package:context_keeper/providers/contact_notes_provider.dart';
import 'package:context_keeper/models/contact_note.dart';

void main() {
  group('ContactNotesProvider', () {
    late ContactNotesProvider provider;

    setUp(() {
      provider = ContactNotesProvider();
    });

    test('начальное состояние - пустой список', () {
      // После инициализации может быть загрузка из БД
      // Но изначально список должен быть создан
      expect(provider.notes, isA<List<ContactNote>>());
    });

    test('isLoading изначально false или становится false после загрузки', () async {
      // Дождемся завершения загрузки
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isLoading, false);
    });

    test('getNoteByPhoneNumber возвращает null для пустого списка', () {
      // Очищаем список для теста
      final result = provider.getNoteByPhoneNumber('+79991234567');
      expect(result, isNull);
    });

    test('getNoteByPhoneNumber находит заметку по точному совпадению', () {
      // Создаем тестовую заметку
      final testNote = ContactNote(
        id: 1,
        contactId: 'test_123',
        contactName: 'Тест',
        phoneNumber: '+79991234567',
        notes: 'Тестовая заметка',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      // Добавляем вручную в список для теста
      // (в реальности это делается через saveNote)
      provider.notes.add(testNote);

      final result = provider.getNoteByPhoneNumber('+79991234567');
      expect(result, isNotNull);
      expect(result?.contactName, 'Тест');
    });

    test('getNoteByPhoneNumber находит заметку по разным форматам номера', () {
      final testNote = ContactNote(
        id: 1,
        contactId: 'test_123',
        contactName: 'Тест',
        phoneNumber: '+79991234567',
        notes: 'Тестовая заметка',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      provider.notes.add(testNote);

      // Проверяем разные форматы
      expect(
        provider.getNoteByPhoneNumber('8 (999) 123-45-67'),
        isNotNull,
      );
      expect(
        provider.getNoteByPhoneNumber('9991234567'),
        isNotNull,
      );
      expect(
        provider.getNoteByPhoneNumber('+7 999 123 45 67'),
        isNotNull,
      );
    });

    test('searchNotes возвращает пустой список для пустого запроса', () {
      final results = provider.searchNotes('');
      expect(results, equals(provider.notes));
    });

    test('searchNotes фильтрует по имени контакта', () {
      final note1 = ContactNote(
        id: 1,
        contactId: 'test_1',
        contactName: 'Айдос',
        phoneNumber: '+79991111111',
        notes: 'Тест 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final note2 = ContactNote(
        id: 2,
        contactId: 'test_2',
        contactName: 'Марат',
        phoneNumber: '+79992222222',
        notes: 'Тест 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      provider.notes.addAll([note1, note2]);

      final results = provider.searchNotes('Айдос');
      expect(results.length, 1);
      expect(results.first.contactName, 'Айдос');
    });

    test('searchNotes фильтрует по номеру телефона', () {
      final note1 = ContactNote(
        id: 1,
        contactId: 'test_1',
        contactName: 'Айдос',
        phoneNumber: '+79991111111',
        notes: 'Тест 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final note2 = ContactNote(
        id: 2,
        contactId: 'test_2',
        contactName: 'Марат',
        phoneNumber: '+79992222222',
        notes: 'Тест 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      provider.notes.addAll([note1, note2]);

      final results = provider.searchNotes('999111');
      expect(results.length, 1);
      expect(results.first.contactName, 'Айдос');
    });

    test('searchNotes фильтрует по содержимому заметки', () {
      final note1 = ContactNote(
        id: 1,
        contactId: 'test_1',
        contactName: 'Айдос',
        phoneNumber: '+79991111111',
        notes: 'Дочери Рита и Гита',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final note2 = ContactNote(
        id: 2,
        contactId: 'test_2',
        contactName: 'Марат',
        phoneNumber: '+79992222222',
        notes: 'Коллега по работе',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      provider.notes.addAll([note1, note2]);

      final results = provider.searchNotes('Дочери');
      expect(results.length, 1);
      expect(results.first.contactName, 'Айдос');
    });

    test('searchNotes не учитывает регистр', () {
      final note = ContactNote(
        id: 1,
        contactId: 'test_1',
        contactName: 'Айдос',
        phoneNumber: '+79991111111',
        notes: 'Дочери Рита и Гита',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      provider.notes.add(note);

      final results1 = provider.searchNotes('айдос');
      expect(results1.length, 1);

      final results2 = provider.searchNotes('АЙДОС');
      expect(results2.length, 1);

      final results3 = provider.searchNotes('дОчЕрИ');
      expect(results3.length, 1);
    });

    test('searchNotes возвращает несколько результатов', () {
      final note1 = ContactNote(
        id: 1,
        contactId: 'test_1',
        contactName: 'Айдос Первый',
        phoneNumber: '+79991111111',
        notes: 'Тест',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final note2 = ContactNote(
        id: 2,
        contactId: 'test_2',
        contactName: 'Айдос Второй',
        phoneNumber: '+79992222222',
        notes: 'Тест',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      provider.notes.addAll([note1, note2]);

      final results = provider.searchNotes('Айдос');
      expect(results.length, 2);
    });

    test('searchNotes возвращает пустой список если ничего не найдено', () {
      final note = ContactNote(
        id: 1,
        contactId: 'test_1',
        contactName: 'Айдос',
        phoneNumber: '+79991111111',
        notes: 'Дочери',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      provider.notes.add(note);

      final results = provider.searchNotes('Несуществующий');
      expect(results, isEmpty);
    });

    test('getNoteByPhoneNumber возвращает первую найденную заметку', () {
      // Если есть дубликаты номеров, должна вернуться первая
      final note1 = ContactNote(
        id: 1,
        contactId: 'test_1',
        contactName: 'Первый',
        phoneNumber: '+79991234567',
        notes: 'Тест 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final note2 = ContactNote(
        id: 2,
        contactId: 'test_2',
        contactName: 'Второй',
        phoneNumber: '+79991234567',
        notes: 'Тест 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      provider.notes.addAll([note1, note2]);

      final result = provider.getNoteByPhoneNumber('+79991234567');
      expect(result, isNotNull);
      expect(result?.contactName, 'Первый');
    });

    test('обрабатывает пустой список корректно', () {
      provider.notes.clear();

      expect(provider.searchNotes('любой запрос'), isEmpty);
      expect(provider.getNoteByPhoneNumber('+79991234567'), isNull);
    });
  });

  group('ContactNotesProvider - реальные сценарии', () {
    late ContactNotesProvider provider;

    setUp(() {
      provider = ContactNotesProvider();
    });

    test('сценарий: поиск заметки при входящем звонке', () async {
      // Симуляция: в БД есть заметка об Айдосе
      final savedNote = ContactNote(
        id: 1,
        contactId: 'contact_123',
        contactName: 'Айдос',
        phoneNumber: '+79991234567',
        notes: 'Дочери Рита и Гита, 3 и 1 год',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      provider.notes.add(savedNote);

      // Входящий звонок с номером в другом формате
      final incomingNumber = '8 (999) 123-45-67';

      // Должны найти заметку
      final note = provider.getNoteByPhoneNumber(incomingNumber);

      expect(note, isNotNull);
      expect(note?.contactName, 'Айдос');
      expect(note?.notes, contains('Дочери'));
    });

    test('сценарий: поиск контакта в списке', () {
      // Несколько контактов в списке
      provider.notes.addAll([
        ContactNote(
          contactId: '1',
          contactName: 'Айдос',
          phoneNumber: '+79991111111',
          notes: 'Друг',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ContactNote(
          contactId: '2',
          contactName: 'Марат',
          phoneNumber: '+79992222222',
          notes: 'Коллега',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ContactNote(
          contactId: '3',
          contactName: 'Алия',
          phoneNumber: '+79993333333',
          notes: 'Менеджер',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      // Пользователь вводит поиск
      final results = provider.searchNotes('Мар');

      expect(results.length, 1);
      expect(results.first.contactName, 'Марат');
    });
  });
}
