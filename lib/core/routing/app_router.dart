import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/guest/presentation/pages/guest_main_layout.dart';
import '../../features/guest/presentation/pages/home_page.dart';
import '../../features/guest/presentation/pages/search_page.dart';
import '../../features/guest/presentation/pages/favorites_page.dart';
import '../../features/guest/presentation/pages/profile_page.dart';
import '../../features/guest/presentation/pages/restaurant_detail_page.dart';
import '../../features/guest/presentation/pages/qr_scanner_page.dart';
import '../../features/guest/presentation/pages/health_profile_page.dart';
import '../../features/guest/presentation/pages/nutrition_log_page.dart';
import '../../features/cateraar/presentation/pages/cateraar_main_layout.dart';
import '../../features/cateraar/presentation/pages/dashboard_page.dart';
import '../../features/cateraar/presentation/pages/restaurants_page.dart';
import '../../features/cateraar/presentation/pages/menu_management_page.dart';
import '../../features/cateraar/presentation/pages/analytics_page.dart';

// Route names
class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  
  // Guest routes
  static const String guestHome = '/guest';
  static const String guestSearch = '/guest/search';
  static const String guestFavorites = '/guest/favorites';
  static const String guestProfile = '/guest/profile';
  static const String restaurantDetail = '/guest/restaurant/:id';
  static const String qrScanner = '/guest/qr-scanner';
  static const String healthProfile = '/guest/health-profile';
  static const String nutritionLog = '/guest/nutrition-log';
  
  // Cateraar routes
  static const String cateraarDashboard = '/cateraar';
  static const String cateraarRestaurants = '/cateraar/restaurants';
  static const String cateraarMenus = '/cateraar/menus';
  static const String cateraarAnalytics = '/cateraar/analytics';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Guest routes with shell
      ShellRoute(
        builder: (context, state, child) => GuestMainLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.guestHome,
            name: 'guest-home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.guestSearch,
            name: 'guest-search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: AppRoutes.guestFavorites,
            name: 'guest-favorites',
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: AppRoutes.guestProfile,
            name: 'guest-profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      
      // Guest detail routes (without shell)
      GoRoute(
        path: AppRoutes.restaurantDetail,
        name: 'restaurant-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return RestaurantDetailPage(restaurantId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.qrScanner,
        name: 'qr-scanner',
        builder: (context, state) => const QrScannerPage(),
      ),
      GoRoute(
        path: AppRoutes.healthProfile,
        name: 'health-profile',
        builder: (context, state) => const HealthProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.nutritionLog,
        name: 'nutrition-log',
        builder: (context, state) => const NutritionLogPage(),
      ),
      
      // Cateraar routes with shell
      ShellRoute(
        builder: (context, state, child) => CateraarMainLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.cateraarDashboard,
            name: 'cateraar-dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.cateraarRestaurants,
            name: 'cateraar-restaurants',
            builder: (context, state) => const RestaurantsPage(),
          ),
          GoRoute(
            path: AppRoutes.cateraarMenus,
            name: 'cateraar-menus',
            builder: (context, state) => const MenuManagementPage(),
          ),
          GoRoute(
            path: AppRoutes.cateraarAnalytics,
            name: 'cateraar-analytics',
            builder: (context, state) => const AnalyticsPage(),
          ),
        ],
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Fout')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Pagina niet gevonden',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'De pagina "${state.uri}" bestaat niet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.onboarding),
              child: const Text('Terug naar start'),
            ),
          ],
        ),
      ),
    ),
    
    // Redirect logic based on authentication state
    redirect: (context, state) {
      // TODO: Implement authentication state checking
      // For now, allow all routes
      return null;
    },
  );
});

// Navigation helper extension
extension AppRouterExtension on GoRouter {
  void goToGuestHome() => go(AppRoutes.guestHome);
  void goToCateraarDashboard() => go(AppRoutes.cateraarDashboard);
  void goToLogin() => go(AppRoutes.login);
  void goToRegister() => go(AppRoutes.register);
  
  void goToRestaurantDetail(int restaurantId) {
    go(AppRoutes.restaurantDetail.replaceAll(':id', restaurantId.toString()));
  }
}

