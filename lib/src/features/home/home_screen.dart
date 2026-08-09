import 'package:flutter/material.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
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
