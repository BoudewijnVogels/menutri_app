import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/api_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _healthProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load user profile
      final userResponse = await ApiService().getCurrentUser();
      final healthResponse = await ApiService().getHealthProfile();

      setState(() {
        _userProfile = userResponse;
        _healthProfile = healthResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Instellingen komen binnenkort')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile header
                    _buildProfileHeader(),

                    const SizedBox(height: 24),

                    // Health profile summary
                    _buildHealthProfileCard(),

                    const SizedBox(height: 16),

                    // Quick stats
                    _buildQuickStats(),

                    const SizedBox(height: 24),

                    // Menu options
                    _buildMenuOptions(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _userProfile;
    if (user == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.withAlphaFraction(mediumBrown, 0.1),
              child: Text(
                _getInitials(user['full_name'] ?? user['email'] ?? ''),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.mediumBrown,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['full_name'] ?? 'Gebruiker',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.withAlphaFraction(mediumBrown, 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Gast',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.mediumBrown,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Profiel bewerken komt binnenkort')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthProfileCard() {
    return Card(
      child: InkWell(
        onTap: () => context.push(AppRoutes.healthProfile),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.health_and_safety,
                      color: AppColors.mediumBrown),
                  const SizedBox(width: 8),
                  Text(
                    'Gezondheidsprofiel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppColors.grey),
                ],
              ),
              const SizedBox(height: 12),
              if (_healthProfile != null) ...[
                Row(
                  children: [
                    _buildHealthStat('BMI',
                        _healthProfile!['bmi']?.toStringAsFixed(1) ?? '-'),
                    const SizedBox(width: 24),
                    _buildHealthStat(
                        'Doel', _healthProfile!['goal'] ?? 'Niet ingesteld'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHealthStat('Calorieën',
                        '${_healthProfile!['daily_calories']?.round() ?? '-'} kcal'),
                    const SizedBox(width: 24),
                    _buildHealthStat(
                        'Activiteit', _healthProfile!['activity_level'] ?? '-'),
                  ],
                ),
              ] else ...[
                Text(
                  'Stel je gezondheidsprofiel in voor gepersonaliseerde aanbevelingen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey,
                      ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push(AppRoutes.healthProfile),
                  child: const Text('Profiel instellen'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.grey,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite,
            title: 'Favorieten',
            value: '12',
            onTap: () => context.go(AppRoutes.guestFavorites),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.restaurant_menu,
            title: 'Gegeten',
            value: '45',
            onTap: () => context.push(AppRoutes.nutritionLog),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.qr_code_scanner,
            title: 'Gescand',
            value: '23',
            onTap: () => context.push(AppRoutes.qrScanner),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.mediumBrown, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.mediumBrown,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Column(
      children: [
        _buildMenuOption(
          icon: Icons.health_and_safety,
          title: 'Gezondheidsprofiel',
          subtitle: 'Beheer je gezondheidsgegevens',
          onTap: () => context.push(AppRoutes.healthProfile),
        ),
        _buildMenuOption(
          icon: Icons.restaurant_menu,
          title: 'Voedingslogboek',
          subtitle: 'Bekijk wat je hebt gegeten',
          onTap: () => context.push(AppRoutes.nutritionLog),
        ),
        _buildMenuOption(
          icon: Icons.notifications,
          title: 'Notificaties',
          subtitle: 'Beheer je meldingen',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notificaties komen binnenkort')),
            );
          },
        ),
        _buildMenuOption(
          icon: Icons.privacy_tip,
          title: 'Privacy',
          subtitle: 'Privacy-instellingen',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Privacy-instellingen komen binnenkort')),
            );
          },
        ),
        _buildMenuOption(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Veelgestelde vragen en contact',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help & Support komt binnenkort')),
            );
          },
        ),
        _buildMenuOption(
          icon: Icons.info,
          title: 'Over Menutri',
          subtitle: 'App-informatie en versie',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Menutri',
              applicationVersion: AppConstants.appVersion,
              applicationLegalese: '© 2024 Menutri. Alle rechten voorbehouden.',
            );
          },
        ),
        const SizedBox(height: 16),
        _buildMenuOption(
          icon: Icons.logout,
          title: 'Uitloggen',
          subtitle: 'Log uit van je account',
          onTap: _logout,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.withAlphaFraction(AppColors.error, 0.1)
                      : AppColors.withAlphaFraction(mediumBrown, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color:
                      isDestructive ? AppColors.error : AppColors.mediumBrown,
                  size: 20,
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
                            color: isDestructive ? AppColors.error : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uitloggen'),
        content: const Text('Weet je zeker dat je wilt uitloggen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Uitloggen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().logout();
        await _storage.deleteAll();

        if (mounted) {
          context.go(AppRoutes.onboarding);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kon niet uitloggen. Probeer opnieuw.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
