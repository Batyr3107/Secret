import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
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

  // Run app with error zone
  runZonedGuarded(
    () async {
      // Initialize database
      await DatabaseService.instance.database;

      // Initialize phone service
      await PhoneService.instance.initialize();

      // Initialize notification service (will skip Firebase if not configured)
      try {
        await NotificationService.instance.initialize();
      } catch (e) {
        debugPrint('⚠️ Notification service initialization failed: $e');
        debugPrint('ℹ️ App will continue without notifications');
      }

      runApp(const MyApp());
    },
    (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace,
        userMessage: 'Критическая ошибка приложения',
      );
    },
  );
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
            brightness: Brightness.light,
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
        themeMode: ThemeMode.system,

        home: const HomeScreen(),
      ),
    );
  }
}
