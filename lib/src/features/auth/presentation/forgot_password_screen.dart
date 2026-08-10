import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
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
    final l10n = context.l10n;
    final validationError = validateEmail(email, strings: l10n);
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
          fallback: l10n.resetEmailError,
          strings: l10n,
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
    final l10n = context.l10n;
    final action = ref.watch(authActionControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
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
                    _sent ? l10n.emailOnTheWay : l10n.forgotPassword,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _sent ? l10n.resetSentBody : l10n.resetRequestBody,
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
                      decoration: InputDecoration(
                        labelText: l10n.emailAddress,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: action.isLoading ? null : _send,
                      child: Text(
                        action.isLoading ? l10n.pleaseWait : l10n.sendResetLink,
                      ),
                    ),
                  ] else
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.backToSignIn),
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
