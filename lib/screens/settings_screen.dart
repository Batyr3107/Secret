import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/export_service.dart';
import '../services/biometric_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _overlayEnabled = true;
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isProcessing = false; // Защита от множественных операций
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Проверяем доступность биометрии
    final biometricStatus = await BiometricService.instance.getBiometricStatus();

    setState(() {
      _overlayEnabled = prefs.getBool('overlay_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

      _biometricAvailable = biometricStatus.isAvailable;
      _biometricEnabled = biometricStatus.isEnabled;

      final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeModeIndex];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('overlay_enabled', _overlayEnabled);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setInt('theme_mode', _themeMode.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          // Отображение
          _buildSection('Отображение'),
          ListTile(
            leading: Icon(
              _themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : _themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto,
            ),
            title: const Text('Тема'),
            subtitle: Text(_getThemeModeLabel(_themeMode)),
            onTap: () => _showThemeDialog(),
          ),

          const Divider(),

          // Уведомления
          _buildSection('Уведомления'),
          SwitchListTile(
            secondary: const Icon(Icons.campaign),
            title: const Text('Overlay при звонке'),
            subtitle: const Text('Показывать заметки поверх экрана (Android)'),
            value: _overlayEnabled,
            onChanged: (value) {
              setState(() => _overlayEnabled = value);
              _saveSettings();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push-уведомления'),
            subtitle: const Text('Получать уведомления о звонках (iOS)'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveSettings();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Вибрация'),
            subtitle: const Text('Вибрировать при показе заметки'),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
              _saveSettings();
            },
          ),

          const Divider(),

          // Безопасность
          _buildSection('Безопасность'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Биометрическая защита'),
            subtitle: Text(
              _biometricAvailable
                  ? 'Запрашивать биометрию при запуске приложения'
                  : 'Недоступна на этом устройстве',
            ),
            value: _biometricEnabled,
            onChanged: _biometricAvailable
                ? (value) => _handleBiometricToggle(value)
                : null,
          ),

          const Divider(),

          // Данные
          _buildSection('Данные'),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Экспорт данных'),
            subtitle: const Text('Сохранить заметки в файл'),
            onTap: () => _showExportDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Импорт данных'),
            subtitle: const Text('Загрузить заметки из файла'),
            onTap: () => _handleImport(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Очистить все данные'),
            subtitle: const Text('Удалить все заметки'),
            onTap: () => _showClearDataDialog(),
          ),

          const Divider(),

          // О приложении
          _buildSection('О приложении'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Версия'),
            subtitle: Text('${AppConstants.appVersion}'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Документация'),
            subtitle: const Text('FAQ, примеры использования и руководства'),
            onTap: () => _showComingSoon('Документация'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Открытый исходный код'),
            subtitle: const Text('GitHub репозиторий'),
            onTap: () => _showComingSoon('GitHub'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Системная';
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Темная';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Системная'),
              subtitle: const Text('Автоматическое переключение'),
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Светлая'),
              subtitle: const Text('Всегда светлая тема'),
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Темная'),
              subtitle: const Text('Всегда темная тема'),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() => _themeMode = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите формат экспорта'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              subtitle: const Text('Универсальный формат для бэкапа'),
              onTap: () {
                Navigator.pop(context);
                _handleExportJson();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              subtitle: const Text('Для Excel и Google Sheets'),
              onTap: () {
                Navigator.pop(context);
                _handleExportCsv();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportJson() async {
    // Защита от множественных нажатий
    if (_isProcessing) {
      debugPrint('⚠️ Операция уже выполняется');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      _showLoadingDialog('Экспорт данных...');

      final file = await ExportService.instance.exportToJson();

      // Проверяем что context всё ещё valid
      if (!mounted || !context.mounted) {
        return;
      }

      Navigator.pop(context); // Close loading dialog

      // Show share dialog
      final shouldShare = await _showShareDialog(file.path);

      if (!mounted || !context.mounted) {
        return;
      }

      if (shouldShare == true) {
        await ExportService.instance.shareBackupFile(file.path);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Экспорт выполнен: ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Безопасное закрытие диалога
      if (mounted && context.mounted) {
        Navigator.pop(context);
      }

      debugPrint('❌ Ошибка экспорта JSON: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка экспорта: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleExportCsv() async {
    // Защита от множественных нажатий
    if (_isProcessing) {
      debugPrint('⚠️ Операция уже выполняется');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      _showLoadingDialog('Экспорт в CSV...');

      final file = await ExportService.instance.exportToCsv();

      // Проверяем что context всё ещё valid
      if (!mounted || !context.mounted) {
        return;
      }

      Navigator.pop(context); // Close loading dialog

      // Show share dialog
      final shouldShare = await _showShareDialog(file.path);

      if (!mounted || !context.mounted) {
        return;
      }

      if (shouldShare == true) {
        await ExportService.instance.shareBackupFile(file.path);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Экспорт выполнен: ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Безопасное закрытие диалога
      if (mounted && context.mounted) {
        Navigator.pop(context);
      }

      debugPrint('❌ Ошибка экспорта CSV: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка экспорта: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleImport() async {
    // Защита от множественных нажатий
    if (_isProcessing) {
      debugPrint('⚠️ Операция уже выполняется');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      _showLoadingDialog('Импорт данных...');

      final importedCount = await ExportService.instance.importFromJson();

      // Проверяем что context всё ещё valid
      if (!mounted || !context.mounted) {
        return;
      }

      Navigator.pop(context); // Close loading dialog

      if (importedCount == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ℹ️ Новых заметок не найдено (возможно, все уже были импортированы)'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Импортировано заметок: $importedCount'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      // Безопасное закрытие диалога
      if (mounted && context.mounted) {
        Navigator.pop(context);
      }

      debugPrint('❌ Ошибка импорта: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка импорта: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showShareDialog(String filePath) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поделиться файлом?'),
        content: Text('Файл сохранен в:\n$filePath\n\nХотите поделиться через другие приложения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Поделиться'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (value) {
      // Включаем биометрию
      final success = await BiometricService.instance.enableBiometric();

      if (success) {
        setState(() => _biometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Биометрическая защита включена'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _biometricEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Не удалось включить биометрическую защиту'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // Отключаем биометрию (требуется подтверждение)
      final shouldDisable = await _showBiometricDisableDialog();
      if (shouldDisable == true) {
        await BiometricService.instance.disableBiometric();
        setState(() => _biometricEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔐 Биометрическая защита отключена'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showBiometricDisableDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отключить биометрию?'),
        content: const Text(
          'Биометрическая защита не будет запрашиваться при запуске приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Отключить'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature будет доступен в следующей версии'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные?'),
        content: const Text(
          'Все заметки будут безвозвратно удалены. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Очистка данных');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
