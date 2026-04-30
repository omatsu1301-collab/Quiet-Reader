import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/work.dart';
import 'models/document.dart';
import 'models/bookmark.dart';
import 'models/highlight.dart';
import 'models/memo.dart';
import 'models/reader_settings.dart';
import 'services/hive_repository.dart';
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

  // Hive 初期化
  await Hive.initFlutter();
  Hive.registerAdapter(WorkAdapter());
  Hive.registerAdapter(DocumentAdapter());
  Hive.registerAdapter(BookmarkAdapter());
  Hive.registerAdapter(HighlightAdapter());
  Hive.registerAdapter(MemoAdapter());
  Hive.registerAdapter(ReaderSettingsAdapter());

  // HiveRepository（AppRepository実装）を初期化してDI
  await HiveRepository.init();
  final repo = HiveRepository();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(repo),
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
