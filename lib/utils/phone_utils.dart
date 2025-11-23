/// Утилиты для работы с номерами телефонов
class PhoneUtils {
  /// Нормализация номера телефона для сравнения
  /// Убирает все символы кроме цифр и +
  /// Приводит к единому формату
  static String normalize(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';

    // Убираем все символы кроме цифр и +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Если начинается с 8 (Россия), заменяем на +7
    if (cleaned.startsWith('8') && cleaned.length == 11) {
      cleaned = '+7${cleaned.substring(1)}';
    }

    // Если начинается с 7 без +, добавляем +
    if (cleaned.startsWith('7') && cleaned.length == 11 && !cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    // Если номер без кода страны (10 цифр), добавляем +7 (для России)
    if (cleaned.length == 10 && !cleaned.startsWith('+')) {
      cleaned = '+7$cleaned';
    }

    return cleaned;
  }

  /// Проверка совпадения двух номеров
  /// Учитывает разные форматы записи
  static bool areEqual(String phone1, String phone2) {
    final normalized1 = normalize(phone1);
    final normalized2 = normalize(phone2);

    // Точное совпадение
    if (normalized1 == normalized2) return true;

    // Совпадение по последним 10 цифрам (для России)
    if (normalized1.length >= 10 && normalized2.length >= 10) {
      final suffix1 = normalized1.substring(normalized1.length - 10);
      final suffix2 = normalized2.substring(normalized2.length - 10);
      return suffix1 == suffix2;
    }

    return false;
  }

  /// Форматирование номера для отображения
  /// +79991234567 -> +7 (999) 123-45-67
  static String format(String phoneNumber) {
    final normalized = normalize(phoneNumber);

    // Для российских номеров
    if (normalized.startsWith('+7') && normalized.length == 12) {
      return '+7 (${normalized.substring(2, 5)}) ${normalized.substring(5, 8)}-${normalized.substring(8, 10)}-${normalized.substring(10)}';
    }

    // Для других номеров возвращаем как есть
    return normalized;
  }

  /// Извлечение последних N цифр
  static String getLastDigits(String phoneNumber, int count) {
    // Убираем все кроме цифр
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length <= count) return digitsOnly;
    return digitsOnly.substring(digitsOnly.length - count);
  }
}
