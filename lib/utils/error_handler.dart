import 'package:flutter/foundation.dart';

/// Глобальный обработчик ошибок
class ErrorHandler {
  static void initialize() {
    // Обработка Flutter ошибок
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack, details.context);
    };

    // Обработка асинхронных ошибок
    // Будет настроено в main.dart через runZonedGuarded
  }

  static void _logError(
    dynamic exception,
    StackTrace? stackTrace,
    DiagnosticsNode? context,
  ) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('ERROR CAUGHT');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Exception: $exception');
    if (context != null) {
      debugPrint('Context: ${context.toDescription()}');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace:\n$stackTrace');
    }
    debugPrint('═══════════════════════════════════════');

    // TODO: Отправить в crash reporting сервис
    // Например: Sentry, Firebase Crashlytics, etc.
    // Sentry.captureException(exception, stackTrace: stackTrace);
  }

  /// Обработка конкретной ошибки с пользовательским сообщением
  static void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? userMessage,
  }) {
    _logError(error, stackTrace, null);

    // Показать пользовательское сообщение если нужно
    if (userMessage != null) {
      debugPrint('User message: $userMessage');
    }
  }

  /// Получить понятное сообщение об ошибке для пользователя
  static String getUserMessage(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString();

      if (errorString.contains('permission')) {
        return 'Нет необходимых разрешений. Проверьте настройки приложения.';
      }

      if (errorString.contains('database') || errorString.contains('sqlite')) {
        return 'Ошибка при работе с базой данных. Попробуйте перезапустить приложение.';
      }

      if (errorString.contains('network') || errorString.contains('connection')) {
        return 'Проблемы с подключением. Проверьте интернет-соединение.';
      }
    }

    return 'Произошла ошибка. Попробуйте еще раз.';
  }
}
