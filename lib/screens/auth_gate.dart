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

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      // Проверяем, включена ли биометрия в настройках
      final isEnabled = await BiometricService.instance.isBiometricEnabled();

      if (!isEnabled) {
        // Биометрия не включена - пускаем сразу
        debugPrint('🔓 Биометрия не включена, пропускаем проверку');
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        return;
      }

      // Биометрия включена - требуем аутентификацию
      setState(() {
        _authRequired = true;
        _isLoading = false;
      });

      // Запрашиваем аутентификацию
      await _authenticate();
    } catch (e) {
      debugPrint('⚠️ Ошибка при проверке биометрии: $e');
      // В случае ошибки пускаем пользователя (graceful degradation)
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticate() async {
    final authenticated = await BiometricService.instance.authenticate(
      localizedReason: 'Подтвердите вход в приложение',
      useErrorDialogs: true,
      stickyAuth: true,
    );

    if (authenticated) {
      debugPrint('✅ Биометрическая аутентификация успешна');
      setState(() {
        _isAuthenticated = true;
      });
    } else {
      debugPrint('❌ Биометрическая аутентификация отклонена');
      // Пользователь отклонил - даем возможность попробовать снова
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
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Разблокировать'),
              ),
            ],
          ),
        ),
      );
    }

    // Аутентификация пройдена или не требуется - показываем основной экран
    return const HomeScreen();
  }
}
