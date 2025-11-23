import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import 'home_screen.dart';

/// Врата аутентификации - проверяет биометрию при запуске если включена
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _authRequired = false;
  bool _isAuthenticating = false; // Защита от множественных нажатий
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      debugPrint('🔐 Начинаем проверку биометрии...');

      // Добавляем таймаут на случай зависания
      final isEnabled = await BiometricService.instance.isBiometricEnabled()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⚠️ Таймаут при проверке биометрии');
              return false;
            },
          );

      debugPrint('🔐 Результат проверки биометрии: $isEnabled');

      if (!isEnabled) {
        // Биометрия не включена - пускаем сразу
        debugPrint('🔓 Биометрия не включена, пропускаем проверку');
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isLoading = false;
          });
        }
        return;
      }

      // Биометрия включена - требуем аутентификацию
      debugPrint('🔒 Биометрия включена, требуем аутентификацию');
      if (mounted) {
        setState(() {
          _authRequired = true;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Ошибка при проверке биометрии: $e');
      debugPrint('Stack trace: $stackTrace');
      // В случае ошибки пускаем пользователя (graceful degradation)
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _authenticate() async {
    // Защита от множественных нажатий
    if (_isAuthenticating) {
      debugPrint('⚠️ Аутентификация уже выполняется');
      return;
    }

    if (mounted) {
      setState(() => _isAuthenticating = true);
    }

    try {
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: 'Подтвердите вход в приложение',
      );

      if (authenticated) {
        debugPrint('✅ Биометрическая аутентификация успешна');
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _failedAttempts = 0; // Сбрасываем счётчик
          });
        }
      } else {
        debugPrint('❌ Биометрическая аутентификация отклонена');
        if (mounted) {
          setState(() {
            _failedAttempts++;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  /// Отключает биометрию и пускает пользователя в приложение
  Future<void> _disableBiometricAndEnter() async {
    // Защита от множественных нажатий
    if (_isAuthenticating) {
      debugPrint('⚠️ Операция уже выполняется');
      return;
    }

    if (mounted) {
      setState(() => _isAuthenticating = true);
    }

    try {
      await BiometricService.instance.disableBiometric();
      debugPrint('🔓 Биометрия отключена пользователем после неудачных попыток');
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Показываем загрузку
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_authRequired && !_isAuthenticated) {
      // Показываем экран блокировки
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Context Keeper',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Приложение защищено биометрией',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (_failedAttempts > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Неудачных попыток: $_failedAttempts',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(_isAuthenticating ? 'Аутентификация...' : 'Разблокировать'),
                ),
                if (_failedAttempts >= 3) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Не можете разблокировать?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isAuthenticating ? null : _disableBiometricAndEnter,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Использовать без биометрии'),
                    style: TextButton.styleFrom(
                      foregroundColor: _isAuthenticating ? null : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Биометрическая защита будет отключена',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Аутентификация пройдена или не требуется - показываем основной экран
    return const HomeScreen();
  }
}
