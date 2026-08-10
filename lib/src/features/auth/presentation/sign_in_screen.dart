import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/data/auth_deep_link.dart';
import 'package:konterreflex/src/features/auth/domain/auth_error_messages.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();
  bool _linkSent = false;
  AuthDeepLinkCoordinator? _deepLinks;
  VoidCallback? _deepLinkErrorListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final deepLinks = ref.read(authDeepLinkCoordinatorProvider);
        _deepLinks = deepLinks;
        void onError() {
          final message = deepLinks.lastError.value;
          if (message == null || !mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          deepLinks.lastError.value = null;
        }

        deepLinks.lastError.addListener(onError);
        _deepLinkErrorListener = onError;
        onError();
      } catch (error) {
        debugPrint('Sign-in deep-link wiring skipped: $error');
      }
    });
  }

  @override
  void dispose() {
    final listener = _deepLinkErrorListener;
    final deepLinks = _deepLinks;
    if (listener != null && deepLinks != null) {
      deepLinks.lastError.removeListener(listener);
    }
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib eine gültige E-Mail-Adresse ein.'),
        ),
      );
      return;
    }

    await ref.read(authActionControllerProvider.notifier).sendSignInOtp(email);
    if (!mounted) return;
    final result = ref.read(authActionControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authErrorMessageFor(
              result.error!,
              fallback: 'Der Anmeldelink konnte nicht gesendet werden.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _linkSent = true);
  }

  Future<void> _completeFromPastedLink() async {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füge den Link aus der E-Mail ein.'),
        ),
      );
      return;
    }

    await ref
        .read(authActionControllerProvider.notifier)
        .completeSignInFromEmailLink(link);
    if (!mounted) return;
    final result = ref.read(authActionControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authErrorMessageFor(
              result.error!,
              fallback:
                  'Anmeldung fehlgeschlagen. Link nicht öffnen – neu anfordern, kopieren und hier einfügen.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authActionControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const IntelligenceOrb(size: 112),
                  const SizedBox(height: 32),
                  Text(
                    'Willkommen bei Konterreflex',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _linkSent
                        ? 'Öffne den Link nicht. Tippe in der Mail lange auf den Link, kopiere ihn und füge ihn hier ein.'
                        : 'Du erhältst einen sicheren Anmeldelink per E-Mail – ohne Passwort.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    enabled: !action.isLoading && !_linkSent,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_linkSent) _sendLink();
                    },
                    decoration: const InputDecoration(
                      labelText: 'E-Mail-Adresse',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_linkSent) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _linkController,
                      enabled: !action.isLoading,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      minLines: 2,
                      maxLines: 4,
                      onSubmitted: (_) => _completeFromPastedLink(),
                      decoration: const InputDecoration(
                        labelText: 'Kopierter Anmeldelink',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: action.isLoading
                        ? null
                        : (_linkSent ? _completeFromPastedLink : _sendLink),
                    child: Text(
                      action.isLoading
                          ? 'Bitte warten …'
                          : _linkSent
                              ? 'Mit Link anmelden'
                              : 'Anmeldelink senden',
                    ),
                  ),
                  if (_linkSent) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: action.isLoading
                          ? null
                          : () async {
                              final data = await Clipboard.getData('text/plain');
                              final text = data?.text?.trim();
                              if (text == null || text.isEmpty) return;
                              setState(() => _linkController.text = text);
                            },
                      child: const Text('Aus Zwischenablage einfügen'),
                    ),
                    TextButton(
                      onPressed: action.isLoading
                          ? null
                          : () {
                              _linkController.clear();
                              setState(() => _linkSent = false);
                            },
                      child: const Text('Andere E-Mail verwenden'),
                    ),
                    TextButton(
                      onPressed: action.isLoading ? null : _sendLink,
                      child: const Text('Neuen Link senden'),
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
