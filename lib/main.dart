import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/app.dart';
import 'package:konterreflex/src/core/config/app_config.dart';
import 'package:konterreflex/src/core/observability/error_reporter.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  const reporter = ConsoleErrorReporter();
  installGlobalErrorReporting(
    reporter: reporter,
    environment: environment,
  );

  runApp(
    ProviderScope(
      child: KonterreflexBootstrap(
        environment: environment,
        reporter: reporter,
      ),
    ),
  );
}

class KonterreflexBootstrap extends ConsumerStatefulWidget {
  const KonterreflexBootstrap({
    required this.environment,
    required this.reporter,
    super.key,
  });

  final String environment;
  final ErrorReporter reporter;

  @override
  ConsumerState<KonterreflexBootstrap> createState() =>
      _KonterreflexBootstrapState();
}

class _KonterreflexBootstrapState extends ConsumerState<KonterreflexBootstrap> {
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await bootstrapKonterreflex().timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error) {
      widget.reporter.capture(
        SafeErrorEvent(
          code: safeErrorCodeFor(error),
          area: ErrorArea.bootstrap,
          fatal: true,
          environment: safeErrorEnvironmentFor(widget.environment),
        ),
      );
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        home: _BootstrapErrorView(error: _error!),
      );
    }
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        home: const _BootstrapLoadingView(),
      );
    }
    return const KonterreflexApp();
  }
}

Future<void> bootstrapKonterreflex() async {
  final config = AppConfig.fromEnvironment();
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
  );
}

class _BootstrapLoadingView extends StatelessWidget {
  const _BootstrapLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Konterreflex',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'App wird gestartet …',
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootstrapErrorView extends StatelessWidget {
  const _BootstrapErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is FormatException
        ? (error as FormatException).message
        : error is TimeoutException
            ? 'Der Start dauert zu lange. Bitte Internet prüfen und die App neu öffnen.'
            : 'Die App konnte nicht gestartet werden.';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 17,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
