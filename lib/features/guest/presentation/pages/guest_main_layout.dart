import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';

class GuestMainLayout extends StatelessWidget {
  final Widget child;

  const GuestMainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const GuestBottomNavigation(),
    );
  }
}

class GuestBottomNavigation extends StatelessWidget {
  const GuestBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (currentLocation.startsWith('/guest/search')) {
      currentIndex = 1;
    } else if (currentLocation.startsWith('/guest/favorites')) {
      currentIndex = 2;
    } else if (currentLocation.startsWith('/guest/profile')) {
      currentIndex = 3;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.withAlphaFraction(AppColors.darkBrown, 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => context.go(AppRoutes.guestHome),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.search_outlined,
                activeIcon: Icons.search,
                label: 'Zoeken',
                isActive: currentIndex == 1,
                onTap: () => context.go(AppRoutes.guestSearch),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: 'Favorieten',
                isActive: currentIndex == 2,
                onTap: () => context.go(AppRoutes.guestFavorites),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profiel',
                isActive: currentIndex == 3,
                onTap: () => context.go(AppRoutes.guestProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.withAlphaFraction(AppColors.mediumBrown, 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.mediumBrown : AppColors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isActive ? AppColors.mediumBrown : AppColors.grey,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
