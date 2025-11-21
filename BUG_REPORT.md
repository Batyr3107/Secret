# 🐛 Отчёт о багах и проблемах логики

**Дата проверки**: 2025-11-21
**Проверено файлов**: 4 (новых/изменённых)

---

## 🔴 КРИТИЧЕСКИЕ БАГИ (требуют немедленного исправления)

### БАГ #1: Пользователь может застрять в AuthGate навсегда ⚠️ CRITICAL

**Файл**: `lib/screens/auth_gate.dart`
**Строки**: 86-118

**Описание**:
Если пользователь включил биометрию, но затем:
- Биометрия перестала работать (сломался сканер)
- Пользователь отклоняет аутентификацию
- Биометрия заблокирована после множественных попыток

То он **навсегда застревает** на экране блокировки! Нет способа:
- Отключить биометрию
- Обойти проверку
- Зайти в настройки

**Текущий код**:
```dart
if (_authRequired && !_isAuthenticated) {
  return Scaffold(
    body: Center(
      child: Column(
        children: [
          // ... только кнопка "Разблокировать"
          FilledButton.icon(
            onPressed: _authenticate, // Вызывает ту же биометрию снова
            label: const Text('Разблокировать'),
          ),
        ],
      ),
    ),
  );
}
```

**Проблема**: Кнопка "Разблокировать" просто вызывает `_authenticate()` снова. Если биометрия не работает - выхода нет!

**Решение**:
Добавить "escape hatch" - кнопку "Использовать приложение без биометрии" после 3 неудачных попыток:

```dart
class _AuthGateState extends State<AuthGate> {
  int _failedAttempts = 0;

  Future<void> _authenticate() async {
    final authenticated = await BiometricService.instance.authenticate(...);

    if (authenticated) {
      setState(() => _isAuthenticated = true);
    } else {
      setState(() => _failedAttempts++);
    }
  }

  // В build():
  if (_failedAttempts >= 3) {
    TextButton(
      onPressed: () async {
        // Отключаем биометрию и пускаем
        await BiometricService.instance.disableBiometric();
        setState(() => _isAuthenticated = true);
      },
      child: const Text('Использовать без биометрии'),
    ),
  }
}
```

**Влияние**: Пользователь может полностью потерять доступ к своим данным!

**Приоритет**: 🔴 **КРИТИЧЕСКИЙ** - исправить немедленно

---

## 🟡 ЛОГИЧЕСКИЕ ПРОБЛЕМЫ (могут вызвать неожиданное поведение)

### Проблема #1: Неправильная проверка в _escapeCsv()

**Файл**: `lib/services/export_service.dart`
**Строки**: 213-223

**Описание**:
Логика экранирования CSV работает неправильно в определённых случаях:

```dart
String _escapeCsv(String value) {
  // 1. Заменяем " на ""
  final escaped = value.replaceAll('"', '""');

  // 2. Проверяем наличие " в уже экранированной строке
  if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
    return '"$escaped"';
  }

  return escaped;
}
```

**Проблема**:
- После `replaceAll('"', '""')` строка `Hello "World"` становится `Hello ""World""`
- Затем проверка `escaped.contains('"')` всегда true если были кавычки
- Это правильное поведение, но нечитаемый код

**Лучше**:
```dart
String _escapeCsv(String value) {
  // Сначала проверяем нужно ли экранирование
  final needsQuotes = value.contains(',') ||
                      value.contains('"') ||
                      value.contains('\n') ||
                      value.contains('\r');

  if (needsQuotes) {
    // Экранируем кавычки и оборачиваем
    return '"${value.replaceAll('"', '""')}"';
  }

  return value;
}
```

**Влияние**: Код работает, но логика запутанная

**Приоритет**: 🟡 **СРЕДНИЙ** - улучшить для читаемости

---

### Проблема #2: shareBackupFile принимает File вместо String path

**Файл**: `lib/services/export_service.dart`
**Строки**: 169-184

**Описание**:
Метод принимает `File`, но это избыточно:

```dart
Future<void> shareBackupFile(File file) async {
  final xFile = XFile(file.path); // Используется только path
  await Share.shareXFiles([xFile], ...);
}
```

**Вызов**:
```dart
// В settings_screen.dart:271
await ExportService.instance.shareBackupFile(file.path); // ❌ Передаём String!
```

**Проблема**: Несоответствие типов! Передаём `String`, но метод ожидает `File`.

**Решение**:
```dart
// Изменить сигнатуру:
Future<void> shareBackupFile(String filePath) async {
  final xFile = XFile(filePath);
  await Share.shareXFiles([xFile], ...);
}
```

**Влияние**: **КОД НЕ КОМПИЛИРУЕТСЯ!** Это серьёзная ошибка.

**Приоритет**: 🔴 **КРИТИЧЕСКИЙ** - исправить немедленно

---

### Проблема #3: Отсутствует проверка на пустой список заметок перед экспортом

**Файл**: `lib/services/export_service.dart`
**Строки**: 17-52 (exportToJson), 56-91 (exportToCsv)

**Описание**:
Если у пользователя нет заметок (`notes.length == 0`), экспорт всё равно создаёт файл:

```dart
Future<File> exportToJson() async {
  final notes = await DatabaseService.instance.getAllNotes();
  // notes может быть пустым []

  final exportData = {
    'notesCount': notes.length, // 0
    'notes': notes.map((note) => note.toMap()).toList(), // []
  };

  // Создаётся файл с пустыми данными
  await file.writeAsString(jsonString);
  return file;
}
```

**Лучше**:
```dart
Future<File> exportToJson() async {
  final notes = await DatabaseService.instance.getAllNotes();

  if (notes.isEmpty) {
    throw Exception('Нет заметок для экспорта');
  }

  // ... остальной код
}
```

**Влияние**: Пользователь получит файл с пустыми данными, может запутаться

**Приоритет**: 🟡 **СРЕДНИЙ** - добавить проверку и сообщение

---

## 🟢 MINOR ISSUES (не критично, но стоит улучшить)

### Issue #1: Не используется mounted check в AuthGate

**Файл**: `lib/screens/auth_gate.dart`
**Строки**: 66-68

**Описание**:
После async операции вызывается `setState()` без проверки `mounted`:

```dart
Future<void> _authenticate() async {
  final authenticated = await BiometricService.instance.authenticate(...);

  if (authenticated) {
    setState(() {  // ⚠️ Нет проверки mounted
      _isAuthenticated = true;
    });
  }
}
```

**Лучше**:
```dart
if (authenticated && mounted) {
  setState(() => _isAuthenticated = true);
}
```

**Приоритет**: 🟢 **НИЗКИЙ** - добавить для consistency

---

### Issue #2: Дублирование кода в _handleExportJson и _handleExportCsv

**Файл**: `lib/screens/settings_screen.dart`
**Строки**: 262-338

**Описание**:
Оба метода имеют идентичную структуру:
1. Показать loading dialog
2. Вызвать export
3. Закрыть loading dialog
4. Показать share dialog
5. Показать snackbar

**Решение**: Создать общий метод `_handleExport(Future<File> Function() exportFn, String type)`

**Приоритет**: 🟢 **НИЗКИЙ** - рефакторинг для DRY

---

### Issue #3: Navigator.pop без проверки context mounted

**Файл**: `lib/screens/settings_screen.dart`
**Строки**: 268, 285, 307, 324, 346, 368

**Описание**:
Вызовы `Navigator.pop(context)` без проверки что context всё ещё mounted:

```dart
Navigator.pop(context); // Close loading dialog
// Что если context уже unmounted?
```

**Лучше**:
```dart
if (mounted && context.mounted) {
  Navigator.pop(context);
}
```

**Приоритет**: 🟢 **НИЗКИЙ** - добавить для надёжности

---

## 📊 Итоговая статистика

| Категория | Количество |
|-----------|------------|
| 🔴 Критические баги | 2 |
| 🟡 Логические проблемы | 3 |
| 🟢 Minor issues | 3 |
| **Всего** | **8** |

---

## 🎯 Приоритет исправлений

### Немедленно (сегодня):
1. **БАГ #1**: Добавить escape hatch в AuthGate
2. **Проблема #2**: Исправить сигнатуру shareBackupFile

### В течение недели:
3. **Проблема #1**: Улучшить _escapeCsv логику
4. **Проблема #3**: Добавить проверку пустого списка в экспорте

### Когда будет время:
5. **Issue #1-3**: Minor улучшения кода

---

## ✅ Рекомендации

После исправления критических багов:

1. Добавить integration тесты для AuthGate:
   - Тест на множественные отклонения биометрии
   - Тест на escape hatch после 3 попыток

2. Добавить unit тесты для ExportService:
   - Тест экспорта пустого списка
   - Тест экранирования CSV с разными символами
   - Тест импорта с дубликатами

3. Code review перед продакшеном:
   - Все async методы должны иметь try-catch
   - Все Navigator.pop должны проверять mounted
   - Все setState должны проверять mounted

---

**Вывод**: Найдено **2 критических бага** которые нужно исправить перед использованием приложения. Остальные проблемы не блокирующие, но желательно исправить для повышения качества.
