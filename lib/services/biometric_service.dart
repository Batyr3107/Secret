import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для биометрической аутентификации
///
/// Предоставляет функции:
/// - Проверка доступности биометрии на устройстве
/// - Аутентификация пользователя через Touch ID / Face ID / отпечаток пальца
/// - Сохранение настроек биометрической защиты
/// - Список доступных биометрических методов
class BiometricService {
  // Singleton pattern
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  // SharedPreferences key
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Проверяет, поддерживает ли устройство биометрическую аутентификацию
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      debugPrint('🔐 Биометрия доступна: $canCheck');
      return canCheck;
    } on PlatformException catch (e) {
      debugPrint('⚠️ Ошибка проверки биометрии: $e');
      return false;
    }
  }

  /// Проверяет, доступна ли хотя бы одна форма аутентификации (биометрия или PIN)
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      debugPrint('🔐 Устройство поддерживает аутентификацию: $isSupported');
      return isSupported;
    } on PlatformException catch (e) {
      debugPrint('⚠️ Ошибка проверки поддержки устройства: $e');
      return false;
    }
  }

  /// Получает список доступных биометрических методов
  ///
  /// Возвращает список типов: face, fingerprint, iris
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      debugPrint('🔐 Доступные методы биометрии: $availableBiometrics');
      return availableBiometrics;
    } on PlatformException catch (e) {
      debugPrint('⚠️ Ошибка получения списка биометрии: $e');
      return [];
    }
  }

  /// Выполняет биометрическую аутентификацию
  ///
  /// Параметры:
  /// - [localizedReason] - причина запроса аутентификации (показывается пользователю)
  /// - [useErrorDialogs] - показывать ли системные диалоги ошибок (по умолчанию true)
  /// - [stickyAuth] - сохранять ли запрос после сворачивания приложения (по умолчанию true)
  ///
  /// Возвращает true если аутентификация успешна
  Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      debugPrint('🔐 Запрос биометрической аутентификации...');

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Разрешаем PIN если биометрия недоступна
        ),
      );

      if (authenticated) {
        debugPrint('✅ Биометрическая аутентификация успешна');
      } else {
        debugPrint('❌ Биометрическая аутентификация отклонена');
      }

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('❌ Ошибка биометрической аутентификации: ${e.code} - ${e.message}');

      // Специальная обработка ошибок
      if (e.code == 'NotAvailable') {
        debugPrint('⚠️ Биометрия недоступна на этом устройстве');
      } else if (e.code == 'NotEnrolled') {
        debugPrint('⚠️ Биометрия не настроена на этом устройстве');
      } else if (e.code == 'LockedOut') {
        debugPrint('⚠️ Биометрия заблокирована из-за множественных попыток');
      } else if (e.code == 'PermanentlyLockedOut') {
        debugPrint('⚠️ Биометрия перманентно заблокирована');
      }

      return false;
    }
  }

  /// Проверяет, включена ли биометрическая защита в настройках приложения
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
    debugPrint('🔐 Биометрическая защита в настройках: $enabled');
    return enabled;
  }

  /// Включает биометрическую защиту в настройках
  ///
  /// Перед включением проверяет доступность биометрии
  /// Возвращает true если успешно включено
  Future<bool> enableBiometric() async {
    try {
      // Проверяем доступность
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        debugPrint('❌ Невозможно включить биометрию: устройство не поддерживает');
        return false;
      }

      // Запрашиваем аутентификацию для подтверждения
      final authenticated = await authenticate(
        localizedReason: 'Подтвердите включение биометрической защиты',
      );

      if (!authenticated) {
        debugPrint('❌ Биометрическая защита не включена: аутентификация не пройдена');
        return false;
      }

      // Сохраняем настройку
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
      debugPrint('✅ Биометрическая защита включена');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка включения биометрии: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Отключает биометрическую защиту в настройках
  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    debugPrint('🔐 Биометрическая защита отключена');
  }

  /// Проверяет доступность и настройку биометрии для первого запуска
  ///
  /// Возвращает описание статуса биометрии для UI
  Future<BiometricStatus> getBiometricStatus() async {
    // Проверяем поддержку устройства
    final isSupported = await isDeviceSupported();
    if (!isSupported) {
      return BiometricStatus(
        isAvailable: false,
        isEnabled: false,
        message: 'Устройство не поддерживает биометрическую аутентификацию',
      );
    }

    // Проверяем доступность биометрии
    final canCheck = await canCheckBiometrics();
    if (!canCheck) {
      return BiometricStatus(
        isAvailable: false,
        isEnabled: false,
        message: 'Биометрия не настроена на устройстве',
      );
    }

    // Получаем список методов
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) {
      return BiometricStatus(
        isAvailable: false,
        isEnabled: false,
        message: 'Биометрические датчики не найдены',
      );
    }

    // Проверяем включено ли в приложении
    final isEnabled = await isBiometricEnabled();

    // Определяем тип биометрии для сообщения
    String biometricType = 'Биометрия';
    if (biometrics.contains(BiometricType.face)) {
      biometricType = 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      biometricType = 'Отпечаток пальца';
    } else if (biometrics.contains(BiometricType.iris)) {
      biometricType = 'Сканер радужки';
    }

    return BiometricStatus(
      isAvailable: true,
      isEnabled: isEnabled,
      biometricTypes: biometrics,
      message: isEnabled
          ? '$biometricType включен'
          : '$biometricType доступен',
    );
  }

  /// Вспомогательный метод для получения человекочитаемого названия типа биометрии
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Отпечаток пальца';
      case BiometricType.iris:
        return 'Сканер радужки';
      case BiometricType.weak:
        return 'Слабая биометрия';
      case BiometricType.strong:
        return 'Сильная биометрия';
    }
  }
}

/// Класс для представления статуса биометрии
class BiometricStatus {
  final bool isAvailable;
  final bool isEnabled;
  final List<BiometricType> biometricTypes;
  final String message;

  BiometricStatus({
    required this.isAvailable,
    required this.isEnabled,
    this.biometricTypes = const [],
    required this.message,
  });

  @override
  String toString() {
    return 'BiometricStatus(available: $isAvailable, enabled: $isEnabled, types: $biometricTypes, message: $message)';
  }
}
