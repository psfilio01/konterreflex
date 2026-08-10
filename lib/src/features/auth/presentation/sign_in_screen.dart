import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/core/localization/localization_extension.dart';
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
    final l10n = context.l10n;
    final validationError = validateEmail(email, strings: l10n) ??
        validatePassword(password, strings: l10n) ??
        (_isSignUp
            ? validatePasswordConfirmation(
                password,
                _passwordConfirmationController.text,
                strings: l10n,
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
          fallback: _isSignUp ? l10n.signUpError : l10n.signInError,
          strings: l10n,
        ),
      );
      return;
    }

    if (outcome == RegistrationOutcome.emailConfirmationRequired) {
      _passwordController.clear();
      _passwordConfirmationController.clear();
      setState(() => _mode = _AuthMode.signIn);
      _showMessage(
        l10n.accountCreatedConfirmation,
      );
    }
  }

  Future<void> _signInWithProvider({required bool apple}) async {
    final l10n = context.l10n;
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
          fallback: apple ? l10n.appleSignInError : l10n.googleSignInError,
          strings: l10n,
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
    final l10n = context.l10n;
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
                      _isSignUp ? l10n.createAccount : l10n.welcomeBack,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _isSignUp ? l10n.signUpIntro : l10n.signInIntro,
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
                      decoration: InputDecoration(
                        labelText: l10n.emailAddress,
                        border: const OutlineInputBorder(),
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
                        labelText: l10n.password,
                        helperText: _isSignUp ? l10n.passwordMinimumHint : null,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          tooltip: _obscurePassword
                              ? l10n.showPassword
                              : l10n.hidePassword,
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
                          labelText: l10n.repeatPassword,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () =>
                                  _obscureConfirmation = !_obscureConfirmation,
                            ),
                            tooltip: _obscureConfirmation
                                ? l10n.showPassword
                                : l10n.hidePassword,
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
                          child: Text(l10n.forgotPassword),
                        ),
                      )
                    else
                      const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: action.isLoading ? null : _submit,
                      child: Text(
                        action.isLoading
                            ? l10n.pleaseWait
                            : _isSignUp
                                ? l10n.createAccount
                                : l10n.signIn,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(l10n.or),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: action.isLoading
                          ? null
                          : () => _signInWithProvider(apple: false),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: Text(l10n.continueWithGoogle),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: action.isLoading
                          ? null
                          : () => _signInWithProvider(apple: true),
                      icon: const Icon(Icons.apple),
                      label: Text(l10n.continueWithApple),
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
                        _isSignUp ? l10n.alreadyHaveAccount : l10n.needAccount,
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
