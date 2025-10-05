import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Auth pages
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';

// Guest pages
import '../../features/guest/presentation/pages/guest_main_layout.dart';
import '../../features/guest/presentation/pages/home_page.dart';
import '../../features/guest/presentation/pages/search_page.dart';
import '../../features/guest/presentation/pages/favorites_page.dart';
import '../../features/guest/presentation/pages/profile_page.dart';
import '../../features/guest/presentation/pages/restaurant_detail_page.dart';
import '../../features/guest/presentation/pages/qr_scanner_page.dart';
import '../../features/guest/presentation/pages/health_profile_page.dart';
import '../../features/guest/presentation/pages/nutrition_log_page.dart';
import '../../features/guest/presentation/pages/external_apps_page.dart';
import '../../features/guest/presentation/pages/activities_page.dart';
import '../../features/guest/presentation/pages/notifications_page.dart';
import '../../features/guest/presentation/pages/edit_profile_page.dart';
import '../../features/guest/presentation/pages/change_password_page.dart';
import '../../features/guest/presentation/pages/delete_account_page.dart';
import '../../features/guest/presentation/pages/help_page.dart';
import '../../features/guest/presentation/pages/settings_page.dart';

// Cateraar pages
import '../../features/cateraar/presentation/pages/cateraar_main_layout.dart';
import '../../features/cateraar/presentation/pages/dashboard_page.dart';
import '../../features/cateraar/presentation/pages/restaurants_page.dart';
import '../../features/cateraar/presentation/pages/menus_page.dart';
import '../../features/cateraar/presentation/pages/add_menu_page.dart';
import '../../features/cateraar/presentation/pages/menu_management_page.dart';
import '../../features/cateraar/presentation/pages/analytics_page.dart';
import '../../features/cateraar/presentation/pages/qr_generator_page.dart';
import '../../features/cateraar/presentation/pages/recipes_page.dart';
import '../../features/cateraar/presentation/pages/ingredients_database_page.dart';
import '../../features/cateraar/presentation/pages/team_management_page.dart';
import '../../features/cateraar/presentation/pages/reviews_moderation_page.dart';
import '../../features/cateraar/presentation/pages/notifications_cateraar_page.dart'
    as cateraar_notifications;
import '../../features/cateraar/presentation/pages/profile_management_page.dart';
import '../../features/cateraar/presentation/pages/settings_page.dart';
import '../../features/cateraar/presentation/pages/help_support_page.dart';
import '../../features/cateraar/presentation/pages/add_restaurant_page.dart';
import '../../features/cateraar/presentation/pages/restaurant_detail_cateraar_page.dart';
import '../../features/cateraar/presentation/pages/add_menu_item_page.dart';
import '../../features/cateraar/presentation/pages/edit_menu_item_page.dart';

final authStateProvider = StateProvider<bool>((ref) => false);
final userRoleProvider = StateProvider<String?>((ref) => null);
final initialRouteProvider =
    StateProvider<String>((ref) => AppRoutes.onboarding);

// Route names
class AppRoutes {
  // Auth routes
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
  static const String externalApps = '/guest/external-apps';
  static const String activities = '/guest/activities';
  static const String guestNotifications = '/guest/notifications';
  static const String editProfile = '/guest/edit-profile';
  static const String changePassword = '/guest/change-password';
  static const String deleteAccount = '/guest/delete-account';
  static const String guestHelp = '/guest/help';
  static const String guestSettings = '/guest/settings';

  // Cateraar routes
  static const String cateraarDashboard = '/cateraar/dashboard';
  static const String cateraarRestaurants = '/cateraar/restaurants';
  static const String cateraarMenus = '/cateraar/menus';
  static const String cateraarAnalytics = '/cateraar/analytics';
  static const String qrGenerator = '/cateraar/qr-generator';
  static const String recipes = '/cateraar/recipes';
  static const String ingredientsDatabase = '/cateraar/ingredients';
  static const String teamManagement = '/cateraar/team';
  static const String reviewsModeration = '/cateraar/reviews';
  static const String cateraarNotifications = '/cateraar/notifications';
  static const String profileManagement = '/cateraar/profile';
  static const String cateraarSettings = '/cateraar/settings';
  static const String cateraarHelp = '/cateraar/help';
  static const String reports = '/cateraar/reports';
  static const String inventory = '/cateraar/inventory';
  static const String promotions = '/cateraar/promotions';
}

final routerProvider = Provider<GoRouter>((ref) {
  final initialRoute = ref.watch(initialRouteProvider);

  return GoRouter(
    initialLocation: initialRoute,
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

      // Guest detail routes
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
      GoRoute(
        path: AppRoutes.externalApps,
        name: 'external-apps',
        builder: (context, state) => const ExternalAppsPage(),
      ),
      GoRoute(
        path: AppRoutes.activities,
        name: 'activities',
        builder: (context, state) => const ActivitiesPage(),
      ),
      GoRoute(
        path: AppRoutes.guestNotifications,
        name: 'guest-notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        name: 'delete-account',
        builder: (context, state) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.guestHelp,
        name: 'guest-help',
        builder: (context, state) => const HelpPage(),
      ),
      GoRoute(
        path: AppRoutes.guestSettings,
        name: 'guest-settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // Cateraar routes with shell
      ShellRoute(
        builder: (context, state, child) =>
            CateraarMainLayout(location: '', child: child),
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
          // ✅ Menus overzicht
          GoRoute(
            path: AppRoutes.cateraarMenus,
            name: 'cateraar-menus',
            builder: (context, state) => const MenusPage(),
          ),
          GoRoute(
            path: AppRoutes.cateraarAnalytics,
            name: 'cateraar-analytics',
            builder: (context, state) => const AnalyticsPage(),
          ),
        ],
      ),

      // Cateraar detail routes
      GoRoute(
        path: '/cateraar/menus/add',
        name: 'cateraar-menus-add',
        builder: (context, state) => const AddMenuPage(),
      ),
      GoRoute(
        path: '/cateraar/menus/:id',
        name: 'cateraar-menu-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MenuManagementPage(menuId: id);
        },
      ),
      GoRoute(
        path: '/cateraar/menu-items/add',
        name: 'cateraar-menu-items-add',
        builder: (context, state) {
          final menuId =
              int.tryParse(state.uri.queryParameters['menu_id'] ?? '');
          if (menuId == null) {
            return const Scaffold(
              body: Center(child: Text('Geen menu_id opgegeven')),
            );
          }
          return AddMenuItemPage(menuId: menuId);
        },
      ),
      GoRoute(
        path: '/cateraar/menu-items/:id/edit',
        name: 'cateraar-menu-items-edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EditMenuItemPage(itemId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.qrGenerator,
        name: 'qr-generator',
        builder: (context, state) => const QRGeneratorPage(),
      ),
      GoRoute(
        path: AppRoutes.recipes,
        name: 'recipes',
        builder: (context, state) => const RecipesPage(),
      ),
      GoRoute(
        path: AppRoutes.ingredientsDatabase,
        name: 'ingredients-database',
        builder: (context, state) => const IngredientsPage(),
      ),
      GoRoute(
        path: AppRoutes.teamManagement,
        name: 'team-management',
        builder: (context, state) => const TeamManagementPage(),
      ),
      GoRoute(
        path: AppRoutes.reviewsModeration,
        name: 'reviews-moderation',
        builder: (context, state) => const ReviewsModerationPage(),
      ),
      GoRoute(
        path: AppRoutes.cateraarNotifications,
        name: 'cateraar-notifications',
        builder: (context, state) =>
            const cateraar_notifications.CateraarNotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.profileManagement,
        name: 'profile-management',
        builder: (context, state) => const CateraarProfileManagementPage(),
      ),
      GoRoute(
        path: AppRoutes.cateraarSettings,
        name: 'cateraar-settings',
        builder: (context, state) => const CateraarSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.cateraarHelp,
        name: 'cateraar-help',
        builder: (context, state) => const CateraarHelpSupportPage(),
      ),

      // Nieuwe restaurant-routes
      GoRoute(
        path: '/cateraar/restaurants/add',
        name: 'cateraar-restaurants-add',
        builder: (context, state) => const AddRestaurantPage(),
      ),
      GoRoute(
        path: '/cateraar/restaurants/:id/edit',
        name: 'cateraar-restaurants-edit',
        builder: (context, state) {
          final restaurant = state.extra as Map<String, dynamic>?;
          return AddRestaurantPage(existingRestaurant: restaurant);
        },
      ),
      GoRoute(
        path: '/cateraar/restaurants/:id',
        name: 'cateraar-restaurant-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return RestaurantDetailCateraarPage(restaurantId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Fout')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
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
    redirect: (context, state) {
      final loggedIn = ref.read(authStateProvider);
      final role = ref.read(userRoleProvider);

      final goingToAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.onboarding;

      if (!loggedIn && !goingToAuth) {
        return AppRoutes.login;
      }

      if (loggedIn && goingToAuth) {
        if (role == 'guest') return AppRoutes.guestHome;
        if (role == 'cateraar') return AppRoutes.cateraarDashboard;
      }

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
