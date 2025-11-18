import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact_note.dart';
import '../providers/contact_notes_provider.dart';

class AddEditNoteScreen extends StatefulWidget {
  final ContactNote? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  Contact? _selectedContact;
  String? _selectedPhoneNumber;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _notesController.text = widget.note!.notes;
    }
  }

  Future<void> _pickContact() async {
    // Request contacts permission
    final permission = await Permission.contacts.request();

    if (!permission.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нужно разрешение на доступ к контактам'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final contacts = await ContactsService.getContacts();
      if (!mounted) return;

      final contact = await showModalBottomSheet<Contact>(
        context: context,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Выберите контакт',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts.elementAt(index);
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (contact.displayName ?? '?')[0].toUpperCase(),
                        ),
                      ),
                      title: Text(contact.displayName ?? 'Без имени'),
                      subtitle: Text(
                        contact.phones?.isNotEmpty == true
                            ? contact.phones!.first.value ?? ''
                            : 'Нет телефона',
                      ),
                      onTap: () => Navigator.pop(context, contact),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (contact != null) {
        setState(() => _selectedContact = contact);

        // If contact has multiple phone numbers, let user choose
        if (contact.phones != null && contact.phones!.length > 1) {
          final phone = await showDialog<Item>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Выберите номер'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: contact.phones!
                    .map((phone) => ListTile(
                          title: Text(phone.value ?? ''),
                          subtitle: Text(phone.label ?? ''),
                          onTap: () => Navigator.pop(context, phone),
                        ))
                    .toList(),
              ),
            ),
          );

          if (phone != null) {
            setState(() => _selectedPhoneNumber = phone.value);
          }
        } else if (contact.phones?.isNotEmpty == true) {
          setState(() => _selectedPhoneNumber = contact.phones!.first.value);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedContact == null && widget.note == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите контакт')),
      );
      return;
    }

    if (_selectedPhoneNumber == null && widget.note == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У контакта нет номера телефона')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final note = ContactNote(
        id: widget.note?.id,
        contactId: widget.note?.contactId ??
            _selectedContact?.identifier ?? '',
        contactName: widget.note?.contactName ??
            _selectedContact?.displayName ?? 'Без имени',
        phoneNumber: widget.note?.phoneNumber ??
            _selectedPhoneNumber ?? '',
        notes: _notesController.text,
      );

      await context.read<ContactNotesProvider>().saveNote(note);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать заметку' : 'Новая заметка'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!isEditing) ...[
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            _selectedContact != null
                                ? (_selectedContact!.displayName ?? '?')[0]
                                    .toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(
                          _selectedContact?.displayName ?? 'Выберите контакт',
                        ),
                        subtitle: Text(
                          _selectedPhoneNumber ?? 'Нет номера',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _pickContact,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.note!.contactName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.note!.phoneNumber,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Заметки о контакте',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText:
                          'Например: Дочери Рита и Гита, 3 и 1 год...',
                      border: OutlineInputBorder(),
                      alignedLabelStyle: AlignedLabelStyle(),
                    ),
                    maxLines: 10,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите заметку';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue[50],
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Эта информация будет показана при входящем звонке',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveNote,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isEditing ? 'Сохранить изменения' : 'Создать заметку',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
