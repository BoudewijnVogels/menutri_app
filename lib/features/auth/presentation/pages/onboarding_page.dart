import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Welkom bij Menutri',
      description:
          'Ontdek gezonde gerechten en restaurants in jouw buurt. Scan QR-codes en bekijk voedingsinformatie.',
      icon: Icons.restaurant,
    ),
    OnboardingItem(
      title: 'Scan & Ontdek',
      description:
          'Scan QR-codes bij restaurants om direct menu\'s en voedingsinformatie te bekijken.',
      icon: Icons.qr_code_scanner,
    ),
    OnboardingItem(
      title: 'Persoonlijke Aanbevelingen',
      description:
          'Krijg gepersonaliseerde aanbevelingen op basis van jouw gezondheidsprofielen doelen.',
      icon: Icons.favorite,
    ),
    OnboardingItem(
      title: 'Kies je rol',
      description:
          'Ben je een gast die restaurants wil ontdekken, of een cateraar die menu\'s wil beheren?',
      icon: Icons.person,
    ),
  ];

  Color _getIconColor(Color bgColor) {
    return bgColor.computeLuminance() < 0.5
        ? AppColors.white
        : AppColors.mediumBrown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: () => _goToRoleSelection(),
                    child: Text(
                      'Overslaan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.mediumBrown,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final bgColor = AppColors.mediumBrown;
                    final iconColor = _getIconColor(bgColor);

                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon in cirkel
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              size: 60,
                              color: iconColor,
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Title
                          Text(
                            item.title,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: AppColors.darkBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Description
                          Text(
                            item.description,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.withAlphaFraction(
                                          AppColors.darkBrown, 0.8),
                                      height: 1.5,
                                    ),
                            textAlign: TextAlign.center,
                          ),

                          // Role selection for last page
                          if (index == _items.length - 1) ...[
                            const SizedBox(height: 48),
                            _buildRoleSelection(),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Page indicator and navigation
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Page indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _items.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.mediumBrown
                                : AppColors.withAlphaFraction(
                                    AppColors.mediumBrown, 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Navigation buttons
                    if (_currentPage < _items.length - 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _currentPage > 0 ? _previousPage : null,
                            child: Text(
                              'Vorige',
                              style: TextStyle(
                                color: _currentPage > 0
                                    ? AppColors.mediumBrown
                                    : AppColors.grey,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _nextPage,
                            child: const Text('Volgende'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      children: [
        _buildRoleCard(
          title: 'Ik ben een Gast',
          description: 'Ontdek restaurants en gezonde gerechten',
          icon: Icons.person,
          onTap: () => _selectRole('gast'),
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          title: 'Ik ben een Cateraar',
          description: 'Beheer restaurants en menu\'s',
          icon: Icons.business,
          onTap: () => _selectRole('cateraar'),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bgColor = AppColors.mediumBrown;
    final iconColor = _getIconColor(bgColor);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToRoleSelection() {
    _pageController.animateToPage(
      _items.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _selectRole(String role) {
    context.go('${AppRoutes.login}?role=$role');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}
