import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'database_service.dart';
import '../models/contact_note.dart';

class PhoneService {
  static final PhoneService instance = PhoneService._init();
  PhoneService._init();

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _initializeAndroid();
    } else if (Platform.isIOS) {
      await _initializeIOS();
    }
  }

  Future<void> _initializeAndroid() async {
    // Request permissions
    final phonePermission = await Permission.phone.request();

    if (phonePermission.isGranted) {
      // Start listening to phone state changes
      PhoneState.stream.listen((event) {
        _handlePhoneStateChange(event);
      });
    } else {
      debugPrint('Phone permission not granted');
    }
  }

  Future<void> _initializeIOS() async {
    // For iOS, we'll use push notifications
    // This will be handled by Firebase Cloud Messaging
    debugPrint('iOS phone service initialized - using push notifications');
  }

  Future<void> _handlePhoneStateChange(PhoneState state) async {
    if (state.status == PhoneStateStatus.CALL_INCOMING) {
      final phoneNumber = state.number;
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Get note for this contact
        final note = await DatabaseService.instance.getNoteByPhoneNumber(phoneNumber);

        if (note != null) {
          // Show overlay with note
          await _showCallOverlay(note);
        }
      }
    }
  }

  Future<void> _showCallOverlay(ContactNote note) async {
    if (Platform.isAndroid) {
      // Request overlay permission if needed
      final overlayPermission = await Permission.systemAlertWindow.request();

      if (overlayPermission.isGranted) {
        // Show overlay window
        // This will be implemented using flutter_overlay_window
        await _showAndroidOverlay(note);
      }
    }
  }

  Future<void> _showAndroidOverlay(ContactNote note) async {
    // Implementation using flutter_overlay_window
    // This will be handled in the Android-specific code
    debugPrint('Showing overlay for: ${note.contactName}');
    debugPrint('Notes: ${note.notes}');
  }

  // Check if all permissions are granted
  Future<bool> hasAllPermissions() async {
    if (Platform.isAndroid) {
      final phonePermission = await Permission.phone.isGranted;
      final overlayPermission = await Permission.systemAlertWindow.isGranted;
      final contactsPermission = await Permission.contacts.isGranted;

      return phonePermission && overlayPermission && contactsPermission;
    } else if (Platform.isIOS) {
      final contactsPermission = await Permission.contacts.isGranted;
      final notificationPermission = await Permission.notification.isGranted;

      return contactsPermission && notificationPermission;
    }

    return false;
  }

  // Request all necessary permissions
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    if (Platform.isAndroid) {
      return await [
        Permission.phone,
        Permission.systemAlertWindow,
        Permission.contacts,
        Permission.notification,
      ].request();
    } else if (Platform.isIOS) {
      return await [
        Permission.contacts,
        Permission.notification,
      ].request();
    }

    return {};
  }
}
