import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure transparent status bar and navigation bar globally
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize essential core services
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await LocalStorageService.instance.init();
    await NotificationService.instance.init();
    Helpers.log('Core services and Firebase initialized successfully.');
  } catch (e) {
    Helpers.log('Error initializing core services: $e');
  }

  runApp(const SydFlowApp());
}
