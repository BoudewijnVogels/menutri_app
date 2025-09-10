import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Zorg dat bindingen/init klaar staan
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialiseren met gegenereerde opties
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics: vang Flutter-framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log als "fatal" zodat het zichtbaar is in Crashlytics
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // (Optioneel) Alleen in release verzamelen. In debug kun je tijdelijk true zetten om te testen.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  // Vang alle overige uncaught errors
  runZonedGuarded(
    () {
      runApp(
        const ProviderScope(
          child: MenutriApp(),
        ),
      );
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class MenutriApp extends ConsumerWidget {
  const MenutriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Menutri',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Router configuration
      routerConfig: router,

      // Localization (Dutch)
      locale: const Locale('nl', 'NL'),

      // Builder for additional configuration
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
