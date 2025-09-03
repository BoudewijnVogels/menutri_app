import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ExternalAppsPage extends ConsumerStatefulWidget {
  const ExternalAppsPage({super.key});

  @override
  ConsumerState<ExternalAppsPage> createState() => _ExternalAppsPageState();
}

class _ExternalAppsPageState extends ConsumerState<ExternalAppsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _healthProfile;

  @override
  void initState() {
    super.initState();
    _loadHealthProfile();
  }

  Future<void> _loadHealthProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getHealthProfile();
      setState(() => _healthProfile = response['health_profile']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden profiel: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectMyFitnessPal() async {
    try {
      final authUrl = await _apiService.getMyFitnessPalAuthUrl();
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij verbinden MyFitnessPal: $e')),
        );
      }
    }
  }

  Future<void> _disconnectApp(String appType) async {
    try {
      await _apiService.updateHealthProfile({
        '${appType}_connected': false,
        if (appType == 'myfitnesspal') 'myfitnesspal_username': null,
      });
      await _loadHealthProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App succesvol losgekoppeld')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij loskoppelen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Externe Apps'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Koppel je favoriete apps',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Synchroniseer je voedingsdata met externe apps voor een compleet overzicht.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // MyFitnessPal
                  _buildAppCard(
                    title: 'MyFitnessPal',
                    description:
                        'Synchroniseer je voedingslogboek en calorieën',
                    icon: Icons.fitness_center,
                    iconColor: Colors.blue,
                    isConnected:
                        _healthProfile?['myfitnesspal_connected'] ?? false,
                    username: _healthProfile?['myfitnesspal_username'],
                    onConnect: _connectMyFitnessPal,
                    onDisconnect: () => _disconnectApp('myfitnesspal'),
                  ),

                  const SizedBox(height: 16),

                  // Google Fit
                  _buildAppCard(
                    title: 'Google Fit',
                    description:
                        'Synchroniseer je activiteiten en verbrande calorieën',
                    icon: Icons.directions_run,
                    iconColor: Colors.green,
                    isConnected:
                        _healthProfile?['google_fit_connected'] ?? false,
                    onConnect: () => _showComingSoon('Google Fit'),
                    onDisconnect: () => _disconnectApp('google_fit'),
                  ),

                  const SizedBox(height: 16),

                  // Apple Health
                  _buildAppCard(
                    title: 'Apple Health',
                    description:
                        'Synchroniseer je gezondheidsdata en activiteiten',
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    isConnected:
                        _healthProfile?['apple_health_connected'] ?? false,
                    onConnect: () => _showComingSoon('Apple Health'),
                    onDisconnect: () => _disconnectApp('apple_health'),
                  ),

                  const SizedBox(height: 32),

                  // Privacy Settings
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.privacy_tip, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Privacy Instellingen',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Gezondheidsdata delen'),
                          subtitle: const Text(
                              'Sta toe dat je data wordt gebruikt voor aanbevelingen'),
                          value: _healthProfile?['share_health_data'] ?? false,
                          onChanged: (value) =>
                              _updatePrivacySetting('share_health_data', value),
                          activeThumbColor: AppColors.primary,
                        ),
                        SwitchListTile(
                          title: const Text('Gepersonaliseerde aanbevelingen'),
                          subtitle: const Text(
                              'Ontvang aanbevelingen op basis van je voorkeuren'),
                          value:
                              _healthProfile?['allow_recommendations'] ?? true,
                          onChanged: (value) => _updatePrivacySetting(
                              'allow_recommendations', value),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Help Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Hulp nodig?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Heb je problemen met het koppelen van apps? Bekijk onze handleiding of neem contact op met support.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primary,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to help page
                          },
                          icon: const Icon(Icons.book),
                          label: const Text('Bekijk Handleiding'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool isConnected,
    String? username,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppColors.primary : AppColors.outline,
          width: isConnected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.withAlphaFraction(iconColor, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Verbonden',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          if (isConnected && username != null) ...[
            const SizedBox(height: 8),
            Text(
              'Verbonden als: $username',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isConnected ? onDisconnect : onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isConnected ? AppColors.error : AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: Text(isConnected ? 'Loskoppelen' : 'Verbinden'),
                ),
              ),
              if (isConnected) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showSyncInfo(title),
                  icon: const Icon(Icons.sync),
                  tooltip: 'Synchronisatie info',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updatePrivacySetting(String setting, bool value) async {
    try {
      await _apiService.updateHealthProfile({setting: value});
      setState(() {
        _healthProfile?[setting] = value;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij bijwerken instelling: $e')),
        );
      }
    }
  }

  void _showComingSoon(String appName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$appName Integratie'),
        content: Text('$appName integratie komt binnenkort beschikbaar!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSyncInfo(String appName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$appName Synchronisatie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laatste synchronisatie: Vandaag 14:30'),
            const SizedBox(height: 8),
            Text('Status: Actief'),
            const SizedBox(height: 8),
            Text('Gesynchroniseerde data:'),
            const SizedBox(height: 4),
            Text('• Voedingslogboek'),
            Text('• Calorieën'),
            Text('• Macro nutriënten'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger manual sync
            },
            child: const Text('Nu Synchroniseren'),
          ),
        ],
      ),
    );
  }
}
