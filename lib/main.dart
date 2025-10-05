import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authService = AuthService();
  final token = await authService.loadToken();
  final storage = const FlutterSecureStorage();
  final role = await storage.read(key: 'userRole');

  // ✅ Bepaal startRoute
  String initialRoute;
  if (token == null) {
    initialRoute = AppRoutes.onboarding;
  } else if (role == 'guest') {
    initialRoute = AppRoutes.guestHome;
  } else if (role == 'cateraar') {
    initialRoute = AppRoutes.cateraarDashboard;
  } else {
    initialRoute = AppRoutes.onboarding; // fallback
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => token != null),
            userRoleProvider.overrideWith((ref) => role),
            initialRouteProvider.overrideWith((ref) => initialRoute),
          ],
          child: const MenutriApp(),
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
    final themeMode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider); // ✅ dynamisch

    return MaterialApp.router(
      title: 'Menutri',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale, // ✅ komt nu uit provider
      supportedLocales: const [
        Locale('nl', 'NL'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
