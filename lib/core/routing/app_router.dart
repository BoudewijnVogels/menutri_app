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
