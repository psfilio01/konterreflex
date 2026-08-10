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

  try {
    final config = AppConfig.fromEnvironment();
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    runApp(const ProviderScope(child: KonterreflexApp()));
  } catch (error) {
    reporter.capture(
      SafeErrorEvent(
        code: safeErrorCodeFor(error),
        area: ErrorArea.bootstrap,
        fatal: true,
        environment: safeErrorEnvironmentFor(environment),
      ),
    );
    runApp(_BootstrapErrorApp(error: error));
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is FormatException
        ? (error as FormatException).message
        : 'Die App konnte nicht gestartet werden.';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
      ),
    );
  }
}
