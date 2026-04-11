import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/pages/home_page.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: CocoSumApp(),
    ),
  );
}

class CocoSumApp extends StatelessWidget {
  const CocoSumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '코코숨',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
