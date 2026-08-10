import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konterreflex/src/admin/admin_app.dart';
import 'package:konterreflex/src/core/config/app_config.dart';
import 'package:konterreflex/src/core/observability/error_reporter.dart';
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
    runApp(const ProviderScope(child: KonterreflexAdminApp()));
  } catch (error) {
    reporter.capture(
      SafeErrorEvent(
        code: safeErrorCodeFor(error),
        area: ErrorArea.bootstrap,
        fatal: true,
        environment: safeErrorEnvironmentFor(environment),
      ),
    );
    rethrow;
  }
}
