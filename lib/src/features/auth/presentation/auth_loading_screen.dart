import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
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
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IntelligenceOrb(
                  size: 88,
                  state: IntelligenceOrbState.thinking,
                  showStatusLabel: false,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Einen Moment …',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
