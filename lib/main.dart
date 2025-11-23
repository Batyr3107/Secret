import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';
import 'services/database_service.dart';
import 'services/phone_service.dart';
import 'services/notification_service.dart';
import 'providers/contact_notes_provider.dart';
import 'utils/error_handler.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling
  ErrorHandler.initialize();

  // Initialize Firebase (with graceful fallback)
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization skipped: $e');
    debugPrint('ℹ️ iOS push notifications will not work without Firebase config');
    debugPrint('ℹ️ This is expected if google-services.json is not configured');
  }

  // Запускаем приложение сразу, сервисы инициализируются в фоне
  debugPrint('🚀 Запуск приложения...');
  runApp(const MyApp());

  // Инициализируем сервисы в фоне (не блокируя UI)
  _initializeServicesInBackground();
}

/// Инициализация сервисов в фоновом режиме
Future<void> _initializeServicesInBackground() async {
  // Initialize database with timeout
  try {
    debugPrint('🗄️ Инициализация базы данных...');
    await DatabaseService.instance.database.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ Таймаут инициализации БД');
        throw TimeoutException('Database initialization timeout');
      },
    );
    debugPrint('✅ База данных инициализирована');
  } catch (e) {
    debugPrint('❌ Ошибка инициализации БД: $e');
  }

  // Initialize phone service with timeout
  try {
    debugPrint('📞 Инициализация телефонного сервиса...');
    await PhoneService.instance.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('⚠️ Таймаут инициализации телефонного сервиса');
      },
    );
    debugPrint('✅ Телефонный сервис инициализирован');
  } catch (e) {
    debugPrint('❌ Phone service initialization failed: $e');
  }

  // Initialize notification service
  try {
    debugPrint('🔔 Инициализация сервиса уведомлений...');
    await NotificationService.instance.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('⚠️ Таймаут инициализации уведомлений');
      },
    );
    debugPrint('✅ Сервис уведомлений инициализирован');
  } catch (e) {
    debugPrint('❌ Notification service initialization failed: $e');
  }

  debugPrint('✅ Все сервисы инициализированы');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContactNotesProvider(),
      child: MaterialApp(
        title: 'Context Keeper',
        debugShowCheckedModeBanner: false,

        // 🌞 Светлая тема
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: AppConstants.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
        ),

        // 🌙 Темная тема
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: AppConstants.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFF1E1E1E),
          ),
        ),

        // 🔄 Автоматическое переключение по системным настройкам
        home: const AuthGate(),
      ),
    );
  }
}
