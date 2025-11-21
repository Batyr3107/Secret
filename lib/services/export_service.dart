import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/contact_note.dart';
import 'database_service.dart';

/// Сервис для экспорта и импорта данных
class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  /// Экспорт всех заметок в JSON формат
  /// Возвращает файл с резервной копией
  Future<File> exportToJson() async {
    try {
      // Получаем все заметки из БД
      final notes = await DatabaseService.instance.getAllNotes();

      // Создаем структуру данных для экспорта
      final exportData = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'notesCount': notes.length,
        'appName': 'Context Keeper',
        'notes': notes.map((note) => note.toMap()).toList(),
      };

      // Конвертируем в JSON с отступами для читаемости
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Получаем директорию для сохранения
      final directory = await getApplicationDocumentsDirectory();

      // Создаем имя файла с timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'context_keeper_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      // Записываем данные в файл
      await file.writeAsString(jsonString);

      debugPrint('✅ Экспорт завершен: ${notes.length} заметок → $fileName');
      return file;
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка экспорта: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Экспорт заметок в CSV формат
  /// Полезно для открытия в Excel/Google Sheets
  Future<File> exportToCsv() async {
    try {
      final notes = await DatabaseService.instance.getAllNotes();

      // Создаем CSV с заголовками
      final csv = StringBuffer();
      csv.writeln('"ID","Contact Name","Phone Number","Notes","Created At","Updated At"');

      // Добавляем каждую заметку как строку CSV
      for (final note in notes) {
        csv.writeln(
          '"${note.id ?? ""}",'
          '"${_escapeCsv(note.contactName)}",'
          '"${_escapeCsv(note.phoneNumber)}",'
          '"${_escapeCsv(note.notes)}",'
          '"${note.createdAt.toIso8601String()}",'
          '"${note.updatedAt.toIso8601String()}"',
        );
      }

      // Сохраняем в файл
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'context_keeper_export_$timestamp.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csv.toString());

      debugPrint('✅ CSV экспорт завершен: ${notes.length} заметок → $fileName');
      return file;
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка CSV экспорта: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Импорт заметок из JSON файла
  /// Возвращает количество успешно импортированных заметок
  Future<int> importFromJson() async {
    try {
      // Открываем диалог выбора файла
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('⚠️ Файл не выбран');
        return 0;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        throw Exception('Не удалось получить путь к файлу');
      }

      // Читаем файл
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Файл не существует');
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Валидация структуры файла
      if (!data.containsKey('notes') || !data.containsKey('version')) {
        throw Exception('Неверный формат файла резервной копии');
      }

      // Проверка версии
      final version = data['version'] as String;
      if (version != '1.0.0') {
        debugPrint('⚠️ Версия файла ($version) отличается от текущей (1.0.0)');
      }

      // Импортируем заметки
      final notesList = data['notes'] as List;
      int successCount = 0;
      int errorCount = 0;

      for (final noteMap in notesList) {
        try {
          final note = ContactNote.fromMap(noteMap as Map<String, dynamic>);

          // Проверяем дубликаты по номеру телефона
          final existing = await DatabaseService.instance
              .getNoteByPhoneNumber(note.phoneNumber);

          if (existing != null) {
            debugPrint('⚠️ Пропуск дубликата: ${note.contactName} (${note.phoneNumber})');
            continue;
          }

          await DatabaseService.instance.insertNote(note);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('❌ Ошибка импорта заметки: $e');
        }
      }

      debugPrint('✅ Импорт завершен: $successCount успешно, $errorCount ошибок');
      return successCount;
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка импорта: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Поделиться файлом резервной копии
  /// Отправляет файл через любое доступное приложение
  Future<void> shareBackupFile(File file) async {
    try {
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        subject: 'Context Keeper - Резервная копия',
        text: 'Резервная копия моих заметок из приложения Context Keeper',
      );
      debugPrint('✅ Файл отправлен на sharing');
    } catch (e) {
      debugPrint('❌ Ошибка sharing: $e');
      rethrow;
    }
  }

  /// Получить путь к последнему экспорту
  Future<File?> getLatestBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('context_keeper_backup'))
          .toList();

      if (files.isEmpty) return null;

      // Сортируем по дате модификации (новые первыми)
      files.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statB.modified.compareTo(statA.modified);
      });

      return files.first;
    } catch (e) {
      debugPrint('❌ Ошибка поиска последнего бэкапа: $e');
      return null;
    }
  }

  /// Экранирование спецсимволов для CSV
  String _escapeCsv(String value) {
    // Экранируем кавычки удвоением
    final escaped = value.replaceAll('"', '""');

    // Если содержит запятые, кавычки или переносы строк - оборачиваем в кавычки
    if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
      return '"$escaped"';
    }

    return escaped;
  }

  /// Удалить старые резервные копии (оставить только N последних)
  Future<int> cleanupOldBackups({int keepCount = 5}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.contains('context_keeper_backup') ||
              f.path.contains('context_keeper_export'))
          .toList();

      if (files.length <= keepCount) {
        return 0;
      }

      // Сортируем по дате модификации (новые первыми)
      files.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statB.modified.compareTo(statA.modified);
      });

      // Удаляем старые файлы
      int deletedCount = 0;
      for (int i = keepCount; i < files.length; i++) {
        try {
          await files[i].delete();
          deletedCount++;
        } catch (e) {
          debugPrint('⚠️ Не удалось удалить ${files[i].path}: $e');
        }
      }

      debugPrint('🧹 Очищено $deletedCount старых бэкапов');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Ошибка очистки бэкапов: $e');
      return 0;
    }
  }
}
