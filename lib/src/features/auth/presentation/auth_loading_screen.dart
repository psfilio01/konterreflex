import 'package:flutter/material.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: 'Anmeldung wird geprüft',
            child: const IntelligenceOrb(size: 88),
          ),
        ),
      ),
    );
  }
}
