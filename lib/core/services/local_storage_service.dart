import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/helpers.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  SharedPreferences? _prefs;
  final ImagePicker _picker = ImagePicker();

  /// ValueNotifier to broadcast profile image changes across the app
  final ValueNotifier<String?> profileImageNotifier = ValueNotifier<String?>(null);

  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      Helpers.log('Error initializing SharedPreferences: $e');
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  Future<void> saveString(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  Future<void> saveBool(String key, bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _getPrefs();
    return prefs.getBool(key);
  }

  Future<void> saveInt(String key, int value) async {
    final prefs = await _getPrefs();
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _getPrefs();
    return prefs.getInt(key);
  }

  Future<void> remove(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }

  Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }

  // --- Profile Image Local Storage ---

  String _profileImageKey(String uid) => 'local_profile_image_path_$uid';

  /// Retrieve the saved local profile image path for a user
  Future<String?> getLocalProfileImagePath(String uid) async {
    try {
      final savedPath = await getString(_profileImageKey(uid));
      if (savedPath != null && savedPath.isNotEmpty) {
        final file = File(savedPath);
        if (await file.exists()) {
          profileImageNotifier.value = savedPath;
          return savedPath;
        }
      }
    } catch (e) {
      Helpers.log('Error reading local profile image path: $e');
    }
    return null;
  }

  /// Pick an image from gallery or camera and save it locally to app storage
  Future<String?> pickAndSaveProfileImage(String uid, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${docsDir.path}/profile_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = 'profile_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${imagesDir.path}/$fileName');

      // Copy picked image to local storage directory
      final bytes = await pickedFile.readAsBytes();
      await savedFile.writeAsBytes(bytes);

      final newPath = savedFile.path;

      // Delete old local profile image file if exists
      final oldPath = await getString(_profileImageKey(uid));
      if (oldPath != null && oldPath != newPath) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (_) {}
        }
      }

      // Save new path in SharedPreferences
      await saveString(_profileImageKey(uid), newPath);

      // Update notifier to refresh UI seamlessly
      profileImageNotifier.value = newPath;
      Helpers.log('Saved local profile image at: $newPath');

      return newPath;
    } catch (e) {
      Helpers.log('Error picking/saving local profile image: $e');
      rethrow;
    }
  }

  /// Delete local profile image for user
  Future<void> removeLocalProfileImage(String uid) async {
    try {
      final savedPath = await getString(_profileImageKey(uid));
      if (savedPath != null) {
        final file = File(savedPath);
        if (await file.exists()) {
          await file.delete();
        }
        await remove(_profileImageKey(uid));
      }
      profileImageNotifier.value = null;
      Helpers.log('Removed local profile image for user: $uid');
    } catch (e) {
      Helpers.log('Error removing local profile image: $e');
    }
  }
}
