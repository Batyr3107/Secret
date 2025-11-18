import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<Permission, PermissionStatus> _permissions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    final permissions = Platform.isAndroid
        ? {
            Permission.phone: await Permission.phone.status,
            Permission.systemAlertWindow:
                await Permission.systemAlertWindow.status,
            Permission.contacts: await Permission.contacts.status,
            Permission.notification: await Permission.notification.status,
          }
        : {
            Permission.contacts: await Permission.contacts.status,
            Permission.notification: await Permission.notification.status,
          };

    setState(() {
      _permissions = permissions;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    setState(() => _isLoading = true);

    final status = await permission.request();

    setState(() {
      _permissions[permission] = status;
      _isLoading = false;
    });

    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog(permission);
    }
  }

  void _showOpenSettingsDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Разрешение заблокировано'),
        content: Text(
          'Разрешение "${_getPermissionName(permission)}" было отклонено. '
          'Откройте настройки приложения, чтобы разрешить вручную.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  String _getPermissionName(Permission permission) {
    if (permission == Permission.phone) return 'Телефон';
    if (permission == Permission.systemAlertWindow) return 'Поверх других окон';
    if (permission == Permission.contacts) return 'Контакты';
    if (permission == Permission.notification) return 'Уведомления';
    return 'Неизвестное';
  }

  String _getPermissionDescription(Permission permission) {
    if (permission == Permission.phone) {
      return 'Для отслеживания входящих звонков';
    }
    if (permission == Permission.systemAlertWindow) {
      return 'Для показа заметок поверх экрана звонка';
    }
    if (permission == Permission.contacts) {
      return 'Для доступа к контактам';
    }
    if (permission == Permission.notification) {
      return 'Для уведомлений о звонках (iOS)';
    }
    return '';
  }

  IconData _getPermissionIcon(Permission permission) {
    if (permission == Permission.phone) return Icons.phone;
    if (permission == Permission.systemAlertWindow) return Icons.layers;
    if (permission == Permission.contacts) return Icons.contacts;
    if (permission == Permission.notification) return Icons.notifications;
    return Icons.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Разрешения'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Необходимые разрешения',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Platform.isAndroid
                              ? 'Для полной работы приложения на Android требуются следующие разрешения:'
                              : 'Для работы на iOS требуются следующие разрешения:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._permissions.entries.map((entry) {
                  final permission = entry.key;
                  final status = entry.value;
                  final isGranted = status.isGranted;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isGranted ? Colors.green[100] : Colors.orange[100],
                        child: Icon(
                          _getPermissionIcon(permission),
                          color: isGranted ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                      title: Text(
                        _getPermissionName(permission),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getPermissionDescription(permission)),
                          const SizedBox(height: 4),
                          Text(
                            isGranted ? 'Разрешено' : 'Не разрешено',
                            style: TextStyle(
                              color: isGranted ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: isGranted
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : ElevatedButton(
                              onPressed: () => _requestPermission(permission),
                              child: const Text('Разрешить'),
                            ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                if (_permissions.values.every((status) => status.isGranted))
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Все разрешения выданы! Приложение готово к работе.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
