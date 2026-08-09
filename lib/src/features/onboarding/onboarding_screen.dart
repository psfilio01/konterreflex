import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';

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
      const SnackBar(
          content: Text('Dein Profil konnte nicht gespeichert werden.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Wie dürfen wir dich ansprechen?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Danach trainierst du vor allem mit deiner Stimme. Deinen Namen kannst du später ändern.',
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nameController,
                    enabled: !action.isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continue(),
                    decoration: const InputDecoration(
                      labelText: 'Vorname oder Anrede',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: action.isLoading ? null : _continue,
                    child: Text(
                        action.isLoading ? 'Wird gespeichert …' : 'Weiter'),
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
