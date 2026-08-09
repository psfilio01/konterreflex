import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/theme/app_theme.dart';
import 'package:konterreflex/src/features/home/home_screen.dart';

class KonterreflexApp extends StatelessWidget {
  const KonterreflexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Konterreflex',
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
