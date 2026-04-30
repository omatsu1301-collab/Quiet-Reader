import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'providers/app_provider.dart';
import 'screens/library_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // システムUIの設定
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Hive初期化
  final storage = StorageService();
  await StorageService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(storage),
      child: const QuietReaderApp(),
    ),
  );
}

class QuietReaderApp extends StatelessWidget {
  const QuietReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiet Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LibraryScreen(),
    );
  }
}
