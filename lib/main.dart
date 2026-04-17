import 'package:flutter/material.dart';
import 'features/main_nav/main_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const FaceWorkApp());
}

class FaceWorkApp extends StatelessWidget {
  const FaceWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceWork Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainScreen(),
    );
  }
}
