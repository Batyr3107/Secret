class ContactNote {
  final int? id;
  final String contactId;
  final String contactName;
  final String phoneNumber;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactNote({
    this.id,
    required this.contactId,
    required this.contactName,
    required this.phoneNumber,
    required this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contact_id': contactId,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ContactNote.fromMap(Map<String, dynamic> map) {
    return ContactNote(
      id: map['id'] as int?,
      contactId: map['contact_id'] as String,
      contactName: map['contact_name'] as String,
      phoneNumber: map['phone_number'] as String,
      notes: map['notes'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ContactNote copyWith({
    int? id,
    String? contactId,
    String? contactName,
    String? phoneNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactNote(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
