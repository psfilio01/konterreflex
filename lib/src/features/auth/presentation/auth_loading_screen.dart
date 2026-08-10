import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: context.l10n.authChecking,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IntelligenceOrb(
                  size: 88,
                  state: IntelligenceOrbState.thinking,
                  showStatusLabel: false,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.oneMoment,
                  style: const TextStyle(
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
