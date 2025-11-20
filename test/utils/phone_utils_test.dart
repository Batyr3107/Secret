import 'package:flutter_test/flutter_test.dart';
import 'package:context_keeper/utils/phone_utils.dart';

void main() {
  group('PhoneUtils.normalize', () {
    test('нормализует российский номер с +7', () {
      expect(
        PhoneUtils.normalize('+7 (999) 123-45-67'),
        '+79991234567',
      );
    });

    test('нормализует номер с 8 (российский формат)', () {
      expect(
        PhoneUtils.normalize('8 (999) 123-45-67'),
        '+79991234567',
      );
    });

    test('нормализует номер с 7 без +', () {
      expect(
        PhoneUtils.normalize('7 999 123 45 67'),
        '+79991234567',
      );
    });

    test('нормализует короткий номер (10 цифр)', () {
      expect(
        PhoneUtils.normalize('9991234567'),
        '+79991234567',
      );
    });

    test('нормализует международный номер', () {
      expect(
        PhoneUtils.normalize('+1 (555) 123-4567'),
        '+15551234567',
      );
    });

    test('удаляет все спецсимволы', () {
      expect(
        PhoneUtils.normalize('+7-999-123-45-67'),
        '+79991234567',
      );
    });

    test('обрабатывает номер с пробелами', () {
      expect(
        PhoneUtils.normalize('+7 999 123 45 67'),
        '+79991234567',
      );
    });

    test('обрабатывает номер со скобками', () {
      expect(
        PhoneUtils.normalize('+7(999)1234567'),
        '+79991234567',
      );
    });

    test('обрабатывает пустую строку', () {
      expect(
        PhoneUtils.normalize(''),
        '',
      );
    });

    test('обрабатывает номер только из цифр', () {
      expect(
        PhoneUtils.normalize('79991234567'),
        '+79991234567',
      );
    });

    test('не изменяет уже нормализованный номер', () {
      expect(
        PhoneUtils.normalize('+79991234567'),
        '+79991234567',
      );
    });

    test('обрабатывает номер с точками', () {
      expect(
        PhoneUtils.normalize('+7.999.123.45.67'),
        '+79991234567',
      );
    });

    test('обрабатывает номер со слешами', () {
      expect(
        PhoneUtils.normalize('+7/999/123-45-67'),
        '+79991234567',
      );
    });
  });

  group('PhoneUtils.areEqual', () {
    test('сравнивает одинаковые номера', () {
      expect(
        PhoneUtils.areEqual('+7 999 123 45 67', '+79991234567'),
        true,
      );
    });

    test('сравнивает разные номера', () {
      expect(
        PhoneUtils.areEqual('+7 999 123 45 67', '+7 888 888 88 88'),
        false,
      );
    });

    test('игнорирует формат при сравнении', () {
      expect(
        PhoneUtils.areEqual(
          '+7 (999) 123-45-67',
          '8-999-123-45-67',
        ),
        true,
      );
    });

    test('сравнивает номера с разными кодами стран (совпадение по суффиксу)', () {
      expect(
        PhoneUtils.areEqual(
          '+79991234567',
          '9991234567',
        ),
        true,
      );
    });

    test('сравнивает короткие номера', () {
      expect(
        PhoneUtils.areEqual('9991234567', '9991234567'),
        true,
      );
    });

    test('сравнивает номера с +7 и 8', () {
      expect(
        PhoneUtils.areEqual('+79991234567', '89991234567'),
        true,
      );
    });

    test('сравнивает номера только из цифр', () {
      expect(
        PhoneUtils.areEqual('79991234567', '89991234567'),
        true,
      );
    });

    test('сравнивает международные номера', () {
      expect(
        PhoneUtils.areEqual('+1 555 123 4567', '+15551234567'),
        true,
      );
    });

    test('возвращает false для разных международных номеров', () {
      expect(
        PhoneUtils.areEqual('+15551234567', '+15551234568'),
        false,
      );
    });

    test('обрабатывает пустые строки', () {
      expect(
        PhoneUtils.areEqual('', ''),
        true,
      );
    });

    test('возвращает false для одной пустой строки', () {
      expect(
        PhoneUtils.areEqual('+79991234567', ''),
        false,
      );
    });
  });

  group('PhoneUtils.format', () {
    test('форматирует российский номер', () {
      expect(
        PhoneUtils.format('+79991234567'),
        '+7 (999) 123-45-67',
      );
    });

    test('форматирует номер из 10 цифр', () {
      expect(
        PhoneUtils.format('9991234567'),
        '+7 (999) 123-45-67',
      );
    });

    test('форматирует номер с 8', () {
      expect(
        PhoneUtils.format('89991234567'),
        '+7 (999) 123-45-67',
      );
    });

    test('форматирует номер с пробелами', () {
      expect(
        PhoneUtils.format('+7 999 123 45 67'),
        '+7 (999) 123-45-67',
      );
    });

    test('возвращает международный номер как есть', () {
      expect(
        PhoneUtils.format('+15551234567'),
        '+15551234567',
      );
    });

    test('обрабатывает пустую строку', () {
      expect(
        PhoneUtils.format(''),
        '',
      );
    });

    test('форматирует номер с дефисами', () {
      expect(
        PhoneUtils.format('+7-999-123-45-67'),
        '+7 (999) 123-45-67',
      );
    });

    test('форматирует номер со скобками', () {
      expect(
        PhoneUtils.format('+7(999)1234567'),
        '+7 (999) 123-45-67',
      );
    });
  });

  group('PhoneUtils.getLastDigits', () {
    test('извлекает последние 4 цифры', () {
      expect(
        PhoneUtils.getLastDigits('+79991234567', 4),
        '4567',
      );
    });

    test('извлекает последние 7 цифр', () {
      expect(
        PhoneUtils.getLastDigits('+79991234567', 7),
        '1234567',
      );
    });

    test('извлекает последние 10 цифр', () {
      expect(
        PhoneUtils.getLastDigits('+79991234567', 10),
        '9991234567',
      );
    });

    test('возвращает весь номер если запрашивается больше цифр', () {
      expect(
        PhoneUtils.getLastDigits('+79991234567', 20),
        '+79991234567',
      );
    });

    test('обрабатывает форматированный номер', () {
      expect(
        PhoneUtils.getLastDigits('+7 (999) 123-45-67', 4),
        '4567',
      );
    });

    test('обрабатывает номер с 8', () {
      expect(
        PhoneUtils.getLastDigits('89991234567', 4),
        '4567',
      );
    });

    test('обрабатывает короткий номер', () {
      expect(
        PhoneUtils.getLastDigits('123', 5),
        '+7123',
      );
    });

    test('извлекает 1 последнюю цифру', () {
      expect(
        PhoneUtils.getLastDigits('+79991234567', 1),
        '7',
      );
    });

    test('обрабатывает пустую строку', () {
      expect(
        PhoneUtils.getLastDigits('', 4),
        '',
      );
    });

    test('извлекает 0 цифр', () {
      expect(
        PhoneUtils.getLastDigits('+79991234567', 0),
        '',
      );
    });
  });

  group('PhoneUtils - интеграционные тесты', () {
    test('нормализация -> форматирование дает корректный результат', () {
      final input = '8 (999) 123-45-67';
      final normalized = PhoneUtils.normalize(input);
      final formatted = PhoneUtils.format(normalized);

      expect(formatted, '+7 (999) 123-45-67');
    });

    test('сравнение работает для разных форматов одного номера', () {
      final variants = [
        '+79991234567',
        '89991234567',
        '79991234567',
        '9991234567',
        '+7 (999) 123-45-67',
        '8-999-123-45-67',
        '+7 999 123 45 67',
      ];

      // Все варианты должны быть равны между собой
      for (var i = 0; i < variants.length; i++) {
        for (var j = 0; j < variants.length; j++) {
          expect(
            PhoneUtils.areEqual(variants[i], variants[j]),
            true,
            reason: '${variants[i]} должен быть равен ${variants[j]}',
          );
        }
      }
    });

    test('извлечение последних цифр работает после нормализации', () {
      final input = '+7 (999) 123-45-67';
      final last4 = PhoneUtils.getLastDigits(input, 4);

      expect(last4, '4567');
    });

    test('реальный пример: Айдос звонит', () {
      final savedNumber = '+79991234567'; // Сохраненный в БД
      final incomingNumber = '8 (999) 123-45-67'; // Входящий звонок

      expect(
        PhoneUtils.areEqual(savedNumber, incomingNumber),
        true,
      );
    });

    test('реальный пример: международный звонок', () {
      final savedNumber = '+15551234567'; // Сохраненный в БД
      final incomingNumber = '+1 (555) 123-4567'; // Входящий звонок

      expect(
        PhoneUtils.areEqual(savedNumber, incomingNumber),
        true,
      );
    });
  });
}
