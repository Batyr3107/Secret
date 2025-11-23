import 'package:flutter/material.dart';

/// УПРОЩЕННАЯ ВЕРСИЯ ДЛЯ ТЕСТА
/// Если эта версия работает - проблема в сервисах
/// Если не работает - проблема в Flutter/Android setup

void main() {
  debugPrint('🚀 ТЕСТ: Запуск упрощенной версии...');
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('✅ ТЕСТ: MaterialApp создается...');
    return MaterialApp(
      title: 'Context Keeper Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Context Keeper - ТЕСТ'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'ПРИЛОЖЕНИЕ РАБОТАЕТ!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Если вы видите этот экран,\nзначит проблема была в сервисах',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  debugPrint('✅ ТЕСТ: Кнопка нажата!');
                },
                child: const Text('Нажми меня для теста'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
