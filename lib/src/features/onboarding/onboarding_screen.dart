import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await ref
        .read(authActionControllerProvider.notifier)
        .completeOnboarding(name);
    if (!mounted || !ref.read(authActionControllerProvider).hasError) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.profileSaveError)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final action = ref.watch(authActionControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.onboardingTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.onboardingBody),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nameController,
                    enabled: !action.isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continue(),
                    decoration: InputDecoration(
                      labelText: l10n.displayNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: action.isLoading ? null : _continue,
                    child: Text(
                        action.isLoading ? l10n.saving : l10n.continueLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
