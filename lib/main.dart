import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/phone_service.dart';
import 'services/notification_service.dart';
import 'providers/contact_notes_provider.dart';
import 'utils/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling
  ErrorHandler.initialize();

  // Run app with error zone
  runZonedGuarded(
    () async {
      // Initialize database
      await DatabaseService.instance.database;

      // Initialize phone service
      await PhoneService.instance.initialize();

      // Initialize notification service
      await NotificationService.instance.initialize();

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
