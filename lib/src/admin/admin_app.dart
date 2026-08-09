import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/theme/app_theme.dart';

class KonterreflexAdminApp extends StatelessWidget {
  const KonterreflexAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Konterreflex Admin',
      theme: AppTheme.light(),
      home: const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Konterreflex Admin')),
        ),
      ),
    );
  }
}
