import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/data/auth_repository.dart';
import 'package:konterreflex/src/features/auth/domain/auth_credentials.dart';
import 'package:konterreflex/src/features/auth/domain/auth_error_messages.dart';
import 'package:konterreflex/src/features/auth/presentation/forgot_password_screen.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

enum _AuthMode { signIn, signUp }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final validationError = validateEmail(email) ??
        validatePassword(password) ??
        (_isSignUp
            ? validatePasswordConfirmation(
                password,
                _passwordConfirmationController.text,
              )
            : null);
    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    final controller = ref.read(authActionControllerProvider.notifier);
    RegistrationOutcome? outcome;
    if (_isSignUp) {
      outcome = await controller.signUpWithPassword(
        email: email,
        password: password,
      );
    } else {
      await controller.signInWithPassword(email: email, password: password);
    }
    if (!mounted) return;

    final action = ref.read(authActionControllerProvider);
    if (action.hasError) {
      _showMessage(
        authErrorMessageFor(
          action.error!,
          fallback: _isSignUp
              ? 'Das Konto konnte nicht erstellt werden.'
              : 'Die Anmeldung ist fehlgeschlagen.',
        ),
      );
      return;
    }

    if (outcome == RegistrationOutcome.emailConfirmationRequired) {
      _passwordController.clear();
      _passwordConfirmationController.clear();
      setState(() => _mode = _AuthMode.signIn);
      _showMessage(
        'Konto erstellt. Bitte bestätige deine E-Mail-Adresse und melde dich danach an.',
      );
    }
  }

  Future<void> _signInWithProvider({required bool apple}) async {
    final controller = ref.read(authActionControllerProvider.notifier);
    if (apple) {
      await controller.signInWithApple();
    } else {
      await controller.signInWithGoogle();
    }
    if (!mounted) return;
    final action = ref.read(authActionControllerProvider);
    if (action.hasError) {
      _showMessage(
        authErrorMessageFor(
          action.error!,
          fallback: apple
              ? 'Die Anmeldung mit Apple ist fehlgeschlagen.'
              : 'Die Anmeldung mit Google ist fehlgeschlagen.',
        ),
      );
    }
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: IntelligenceOrb(size: 112),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _isSignUp ? 'Konto erstellen' : 'Willkommen zurück',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _isSignUp
                          ? 'Erstelle dein Konterreflex-Konto mit E-Mail und Passwort.'
                          : 'Melde dich an und setze dein Training fort.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _emailController,
                      enabled: !action.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail-Adresse',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _passwordController,
                      enabled: !action.isLoading,
                      obscureText: _obscurePassword,
                      autofillHints: [
                        _isSignUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      textInputAction: _isSignUp
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_isSignUp) _submit();
                      },
                      decoration: InputDecoration(
                        labelText: 'Passwort',
                        helperText: _isSignUp ? 'Mindestens 8 Zeichen' : null,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          tooltip: _obscurePassword
                              ? 'Passwort anzeigen'
                              : 'Passwort verbergen',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _passwordConfirmationController,
                        enabled: !action.isLoading,
                        obscureText: _obscureConfirmation,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Passwort wiederholen',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () =>
                                  _obscureConfirmation = !_obscureConfirmation,
                            ),
                            tooltip: _obscureConfirmation
                                ? 'Passwort anzeigen'
                                : 'Passwort verbergen',
                            icon: Icon(
                              _obscureConfirmation
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: action.isLoading
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ForgotPasswordScreen(
                                        initialEmail:
                                            _emailController.text.trim(),
                                      ),
                                    ),
                                  ),
                          child: const Text('Passwort vergessen?'),
                        ),
                      )
                    else
                      const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: action.isLoading ? null : _submit,
                      child: Text(
                        action.isLoading
                            ? 'Bitte warten …'
                            : _isSignUp
                                ? 'Konto erstellen'
                                : 'Anmelden',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('oder'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: action.isLoading
                          ? null
                          : () => _signInWithProvider(apple: false),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Text('Mit Google fortfahren'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: action.isLoading
                          ? null
                          : () => _signInWithProvider(apple: true),
                      icon: const Icon(Icons.apple),
                      label: const Text('Mit Apple fortfahren'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: action.isLoading
                          ? null
                          : () {
                              _passwordController.clear();
                              _passwordConfirmationController.clear();
                              setState(() {
                                _mode = _isSignUp
                                    ? _AuthMode.signIn
                                    : _AuthMode.signUp;
                              });
                            },
                      child: Text(
                        _isSignUp
                            ? 'Du hast schon ein Konto? Anmelden'
                            : 'Noch kein Konto? Jetzt registrieren',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
