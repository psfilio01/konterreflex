import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:konterreflex/src/core/routing/app_router.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Einstellungen',
            onPressed: () => context.pushNamed(AppRoute.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IntelligenceOrb(),
                SizedBox(height: 32),
                Text('Konterreflex',
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Hören. Reagieren. Reflektieren. Wiederholen.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
