import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/domain/auth_credentials.dart';
import 'package:konterreflex/src/features/auth/domain/auth_error_messages.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final password = _passwordController.text;
    final validationError = validatePassword(password) ??
        validatePasswordConfirmation(password, _confirmationController.text);
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    await ref
        .read(authActionControllerProvider.notifier)
        .updatePassword(password);
    if (!mounted) return;
    final action = ref.read(authActionControllerProvider);
    if (action.hasError) {
      _showMessage(
        authErrorMessageFor(
          action.error!,
          fallback: 'Das Passwort konnte nicht geändert werden.',
        ),
      );
      return;
    }
    _showMessage('Dein Passwort wurde geändert.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authActionControllerProvider);
    final user = ref.watch(authUserProvider).asData?.value;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Neues Passwort',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Lege ein neues Passwort mit mindestens 8 Zeichen fest.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (user == null)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    TextField(
                      controller: _passwordController,
                      enabled: !action.isLoading,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Neues Passwort',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _confirmationController,
                      enabled: !action.isLoading,
                      obscureText: _obscureConfirmation,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _update(),
                      decoration: InputDecoration(
                        labelText: 'Passwort wiederholen',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirmation = !_obscureConfirmation,
                          ),
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: action.isLoading ? null : _update,
                      child: Text(
                        action.isLoading
                            ? 'Bitte warten …'
                            : 'Passwort speichern',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
