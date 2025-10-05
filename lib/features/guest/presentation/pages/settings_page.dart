import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routing/app_router.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Algemeen
  double _fontScale = 1.0;
  String _themeMode = 'system'; // 'light', 'dark', 'system'

  // Meldingen
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _promoNotifications = false;
  bool _summaryNotifications = false;

  // Privacy & Beveiliging
  bool _twoFactor = false;
  bool _useBiometrics = false;
  bool _shareLocation = false;

  // Overig
  String _startPage = 'home'; // 'home', 'favorites', 'profile'

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final themeMode = ref.read(themeNotifierProvider);
    setState(() {
      if (themeMode == ThemeMode.dark) {
        _themeMode = 'dark';
      } else if (themeMode == ThemeMode.light) {
        _themeMode = 'light';
      } else {
        _themeMode = 'system';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Algemeen
          const ListTile(
            title:
                Text('Algemeen', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.mediumBrown),
            title: const Text('Taal'),
            subtitle: const Text('Kies de app-taal'),
            trailing: DropdownButton<String>(
              value:
                  ref.watch(localeNotifierProvider).languageCode, // ✅ provider
              items: const [
                DropdownMenuItem(value: 'nl', child: Text('Nederlands')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (val) {
                if (val == null) return;
                if (val == 'nl') {
                  ref
                      .read(localeNotifierProvider.notifier)
                      .setLocale(const Locale('nl', 'NL'));
                } else if (val == 'en') {
                  ref
                      .read(localeNotifierProvider.notifier)
                      .setLocale(const Locale('en', 'US'));
                }
              },
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.format_size, color: AppColors.mediumBrown),
            title: const Text('Lettergrootte'),
            subtitle: const Text('Pas de grootte van de tekst aan'),
            trailing: DropdownButton<double>(
              value: _fontScale,
              items: const [
                DropdownMenuItem(value: 0.9, child: Text('Klein')),
                DropdownMenuItem(value: 1.0, child: Text('Normaal')),
                DropdownMenuItem(value: 1.2, child: Text('Groot')),
              ],
              onChanged: (val) => setState(() => _fontScale = val!),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.brightness_6, color: AppColors.mediumBrown),
            title: const Text('Thema'),
            subtitle: const Text('Kies licht, donker of systeeminstelling'),
            trailing: DropdownButton<String>(
              value: _themeMode,
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Licht')),
                DropdownMenuItem(value: 'dark', child: Text('Donker')),
                DropdownMenuItem(value: 'system', child: Text('Systeem')),
              ],
              onChanged: (val) async {
                if (val == null) return;
                setState(() => _themeMode = val);

                if (val == 'dark') {
                  await ref.read(themeNotifierProvider.notifier).setDarkTheme();
                } else if (val == 'light') {
                  await ref
                      .read(themeNotifierProvider.notifier)
                      .setLightTheme();
                } else {
                  await ref
                      .read(themeNotifierProvider.notifier)
                      .setSystemTheme();
                }
              },
            ),
          ),
          const Divider(),

          // Meldingen
          const ListTile(
            title: Text('Meldingen',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            value: _pushNotifications,
            activeThumbColor: AppColors.mediumBrown,
            title: const Text('Push notificaties'),
            subtitle: const Text('Ontvang meldingen van Menutri'),
            onChanged: (value) => setState(() => _pushNotifications = value),
          ),
          SwitchListTile(
            value: _emailNotifications,
            activeThumbColor: AppColors.mediumBrown,
            title: const Text('E-mail notificaties'),
            subtitle: const Text('Ontvang updates via e-mail'),
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
          SwitchListTile(
            value: _promoNotifications,
            activeThumbColor: AppColors.mediumBrown,
            title: const Text('Promotionele meldingen'),
            subtitle: const Text('Aanbiedingen en promoties ontvangen'),
            onChanged: (value) => setState(() => _promoNotifications = value),
          ),
          SwitchListTile(
            value: _summaryNotifications,
            activeThumbColor: AppColors.mediumBrown,
            title: const Text('Samenvatting'),
            subtitle:
                const Text('Ontvang dagelijkse of wekelijkse samenvatting'),
            onChanged: (value) => setState(() => _summaryNotifications = value),
          ),
          const Divider(),

          // Privacy & Beveiliging
          const ListTile(
            title: Text('Privacy & Beveiliging',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            value: _twoFactor,
            activeThumbColor: AppColors.mediumBrown,
            title: const Text('Twee-stapsverificatie'),
            subtitle: const Text('Extra beveiliging bij inloggen'),
            onChanged: (value) => setState(() => _twoFactor = value),
          ),
          SwitchListTile(
            value: _useBiometrics,
            activeThumbColor: AppColors.mediumBrown,
            title: const Text('App-vergrendeling'),
            subtitle: const Text('Gebruik FaceID/TouchID of pincode'),
            onChanged: (value) => setState(() => _useBiometrics = value),
          ),
          SwitchListTile(
            value: _shareLocation,
            activeThumbColor: AppColors.mediumBrown,
            title: const Text('Locatie delen'),
            subtitle:
                const Text('Gebruik locatie voor aanbevelingen in de buurt'),
            onChanged: (value) => setState(() => _shareLocation = value),
          ),
          const Divider(),

          // Accountbeheer
          const ListTile(
            title:
                Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.mediumBrown),
            title: const Text('Wachtwoord wijzigen'),
            onTap: () => context.push(AppRoutes.changePassword),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.mediumBrown),
            title: const Text('Profiel bewerken'),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Account verwijderen'),
            onTap: () => context.push(AppRoutes.deleteAccount),
          ),
          const Divider(),

          // Overig
          const ListTile(
            title:
                Text('Overig', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: AppColors.mediumBrown),
            title: const Text('Standaard startpagina'),
            subtitle: const Text('Kies waar de app opent'),
            trailing: DropdownButton<String>(
              value: _startPage,
              items: const [
                DropdownMenuItem(value: 'home', child: Text('Home')),
                DropdownMenuItem(value: 'favorites', child: Text('Favorieten')),
                DropdownMenuItem(value: 'profile', child: Text('Profiel')),
              ],
              onChanged: (val) => setState(() => _startPage = val!),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.link, color: AppColors.mediumBrown),
            title: const Text('Externe koppelingen'),
            subtitle:
                const Text('Beheer koppelingen zoals MyFitnessPal, Google Fit'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Externe koppelingen komen binnenkort')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback, color: AppColors.mediumBrown),
            title: const Text('Feedback sturen'),
            subtitle: const Text('Geef ons je mening over Menutri'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Feedbackformulier komt binnenkort')),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
