import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/domain/auth_credentials.dart';
import 'package:konterreflex/src/features/auth/domain/auth_error_messages.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    final validationError = validateEmail(email);
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }
    await ref
        .read(authActionControllerProvider.notifier)
        .requestPasswordReset(email);
    if (!mounted) return;
    final action = ref.read(authActionControllerProvider);
    if (action.hasError) {
      _showMessage(
        authErrorMessageFor(
          action.error!,
          fallback: 'Die E-Mail konnte nicht gesendet werden.',
        ),
      );
      return;
    }
    setState(() => _sent = true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authActionControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Passwort zurücksetzen')),
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
                    _sent ? 'E-Mail ist unterwegs' : 'Passwort vergessen?',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _sent
                        ? 'Falls ein Konto für diese Adresse besteht, erhältst du einen Link zum Festlegen eines neuen Passworts.'
                        : 'Gib deine E-Mail-Adresse ein. Wir senden dir einen sicheren Link zum Festlegen eines neuen Passworts.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (!_sent) ...[
                    TextField(
                      controller: _emailController,
                      enabled: !action.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        labelText: 'E-Mail-Adresse',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: action.isLoading ? null : _send,
                      child: Text(
                        action.isLoading
                            ? 'Bitte warten …'
                            : 'Reset-Link senden',
                      ),
                    ),
                  ] else
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Zurück zur Anmeldung'),
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
