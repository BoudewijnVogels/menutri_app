import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CateraarSettingsPage extends ConsumerStatefulWidget {
  const CateraarSettingsPage({super.key});

  @override
  ConsumerState<CateraarSettingsPage> createState() =>
      _CateraarSettingsPageState();
}

class _CateraarSettingsPageState extends ConsumerState<CateraarSettingsPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _settings = {};

  // App Settings
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoSync = true;
  bool _offlineMode = false;
  String _language = 'nl';
  String _currency = 'EUR';
  String _dateFormat = 'dd/MM/yyyy';
  String _timeFormat = '24h';
  String _theme = 'system';

  // Business Settings
  bool _autoApproveReviews = false;
  bool _allowGuestReviews = true;
  bool _requireReservation = false;
  bool _enableDelivery = false;
  bool _enableTakeaway = true;
  bool _showPrices = true;
  bool _showNutrition = true;
  bool _showAllergens = true;
  String _defaultMenuStatus = 'active';
  String _businessHours = 'custom';
  int _maxReservationDays = 30;
  int _minReservationHours = 2;

  // Notification Settings
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushReviews = true;
  bool _pushOrders = true;
  bool _pushTeam = true;
  bool _pushSystem = true;
  bool _pushMarketing = false;
  bool _emailDigest = true;
  bool _weeklyReport = true;
  bool _monthlyReport = true;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  bool _quietHoursEnabled = false;

  // Privacy & Security Settings
  bool _twoFactorAuth = false;
  bool _loginNotifications = true;
  bool _dataCollection = true;
  bool _analyticsTracking = true;
  bool _marketingCookies = false;
  bool _shareData = false;
  String _dataRetention = '2_years';
  String _sessionTimeout = '30_minutes';

  // Integration Settings
  bool _googleMapsEnabled = true;
  bool _myFitnessPalEnabled = true;
  bool _googleAnalyticsEnabled = false;
  bool _facebookPixelEnabled = false;
  String _paymentProvider = 'stripe';
  String _emailProvider = 'sendgrid';
  String _smsProvider = 'twilio';

  final Map<String, String> _languageOptions = {
    'nl': 'Nederlands',
    'en': 'English',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
  };

  final Map<String, String> _currencyOptions = {
    'EUR': '€ Euro',
    'USD': '\$ US Dollar',
    'GBP': '£ British Pound',
    'CHF': 'CHF Swiss Franc',
  };

  final Map<String, String> _themeOptions = {
    'system': 'Systeem',
    'light': 'Licht',
    'dark': 'Donker',
  };

  final Map<String, String> _dateFormatOptions = {
    'dd/MM/yyyy': '31/12/2023',
    'MM/dd/yyyy': '12/31/2023',
    'yyyy-MM-dd': '2023-12-31',
    'dd-MM-yyyy': '31-12-2023',
  };

  final Map<String, String> _timeFormatOptions = {
    '24h': '24 uur (13:30)',
    '12h': '12 uur (1:30 PM)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getSettings();
      final settings = response['settings'] ?? {};

      setState(() {
        _settings = settings;
        _isLoading = false;
      });

      _populateSettings();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden instellingen: $e')),
        );
      }
    }
  }

  void _populateSettings() {
    // App Settings
    _darkMode = _settings['dark_mode'] ?? false;
    _pushNotifications = _settings['push_notifications'] ?? true;
    _soundEnabled = _settings['sound_enabled'] ?? true;
    _vibrationEnabled = _settings['vibration_enabled'] ?? true;
    _autoSync = _settings['auto_sync'] ?? true;
    _offlineMode = _settings['offline_mode'] ?? false;
    _language = _settings['language'] ?? 'nl';
    _currency = _settings['currency'] ?? 'EUR';
    _dateFormat = _settings['date_format'] ?? 'dd/MM/yyyy';
    _timeFormat = _settings['time_format'] ?? '24h';
    _theme = _settings['theme'] ?? 'system';

    // Business Settings
    _autoApproveReviews = _settings['auto_approve_reviews'] ?? false;
    _allowGuestReviews = _settings['allow_guest_reviews'] ?? true;
    _requireReservation = _settings['require_reservation'] ?? false;
    _enableDelivery = _settings['enable_delivery'] ?? false;
    _enableTakeaway = _settings['enable_takeaway'] ?? true;
    _showPrices = _settings['show_prices'] ?? true;
    _showNutrition = _settings['show_nutrition'] ?? true;
    _showAllergens = _settings['show_allergens'] ?? true;
    _defaultMenuStatus = _settings['default_menu_status'] ?? 'active';
    _businessHours = _settings['business_hours'] ?? 'custom';
    _maxReservationDays = _settings['max_reservation_days'] ?? 30;
    _minReservationHours = _settings['min_reservation_hours'] ?? 2;

    // Notification Settings
    _emailNotifications = _settings['email_notifications'] ?? true;
    _smsNotifications = _settings['sms_notifications'] ?? false;
    _pushReviews = _settings['push_reviews'] ?? true;
    _pushOrders = _settings['push_orders'] ?? true;
    _pushTeam = _settings['push_team'] ?? true;
    _pushSystem = _settings['push_system'] ?? true;
    _pushMarketing = _settings['push_marketing'] ?? false;
    _emailDigest = _settings['email_digest'] ?? true;
    _weeklyReport = _settings['weekly_report'] ?? true;
    _monthlyReport = _settings['monthly_report'] ?? true;
    _quietHoursStart = _settings['quiet_hours_start'] ?? '22:00';
    _quietHoursEnd = _settings['quiet_hours_end'] ?? '08:00';
    _quietHoursEnabled = _settings['quiet_hours_enabled'] ?? false;

    // Privacy & Security Settings
    _twoFactorAuth = _settings['two_factor_auth'] ?? false;
    _loginNotifications = _settings['login_notifications'] ?? true;
    _dataCollection = _settings['data_collection'] ?? true;
    _analyticsTracking = _settings['analytics_tracking'] ?? true;
    _marketingCookies = _settings['marketing_cookies'] ?? false;
    _shareData = _settings['share_data'] ?? false;
    _dataRetention = _settings['data_retention'] ?? '2_years';
    _sessionTimeout = _settings['session_timeout'] ?? '30_minutes';

    // Integration Settings
    _googleMapsEnabled = _settings['google_maps_enabled'] ?? true;
    _myFitnessPalEnabled = _settings['myfitnesspal_enabled'] ?? true;
    _googleAnalyticsEnabled = _settings['google_analytics_enabled'] ?? false;
    _facebookPixelEnabled = _settings['facebook_pixel_enabled'] ?? false;
    _paymentProvider = _settings['payment_provider'] ?? 'stripe';
    _emailProvider = _settings['email_provider'] ?? 'sendgrid';
    _smsProvider = _settings['sms_provider'] ?? 'twilio';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Instellingen'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSettings,
            tooltip: 'Opslaan',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'reset_defaults':
                  _showResetDefaultsDialog();
                  break;
                case 'export_settings':
                  _exportSettings();
                  break;
                case 'import_settings':
                  _importSettings();
                  break;
                case 'clear_cache':
                  _clearCache();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset_defaults',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Standaard Instellingen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_settings',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Instellingen Exporteren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import_settings',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Instellingen Importeren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_cache',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Cache Wissen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.onPrimary,
            labelColor: AppColors.onPrimary,
            unselectedLabelColor:
                AppColors.withAlphaFraction(AppColors.onPrimary, 0.7),
            isScrollable: true,
            tabs: const [
              Tab(text: 'App'),
              Tab(text: 'Bedrijf'),
              Tab(text: 'Notificaties'),
              Tab(text: 'Privacy'),
              Tab(text: 'Integraties'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppSettingsTab(),
                _buildBusinessSettingsTab(),
                _buildNotificationSettingsTab(),
                _buildPrivacySettingsTab(),
                _buildIntegrationSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildAppSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appearance
          _buildSectionTitle('Uiterlijk'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildDropdownTile(
                  'Thema',
                  'Kies het app thema',
                  Icons.palette,
                  _theme,
                  _themeOptions,
                  (value) => setState(() => _theme = value!),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Donkere Modus',
                  'Gebruik donker thema',
                  Icons.dark_mode,
                  _darkMode,
                  (value) => setState(() => _darkMode = value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Language & Region
          _buildSectionTitle('Taal & Regio'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildDropdownTile(
                  'Taal',
                  'App taal instellen',
                  Icons.language,
                  _language,
                  _languageOptions,
                  (value) => setState(() => _language = value!),
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  'Valuta',
                  'Standaard valuta',
                  Icons.euro,
                  _currency,
                  _currencyOptions,
                  (value) => setState(() => _currency = value!),
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  'Datum Formaat',
                  'Datum weergave formaat',
                  Icons.calendar_today,
                  _dateFormat,
                  _dateFormatOptions,
                  (value) => setState(() => _dateFormat = value!),
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  'Tijd Formaat',
                  'Tijd weergave formaat',
                  Icons.access_time,
                  _timeFormat,
                  _timeFormatOptions,
                  (value) => setState(() => _timeFormat = value!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notifications
          _buildSectionTitle('App Notificaties'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Push Notificaties',
                  'Ontvang push notificaties',
                  Icons.notifications,
                  _pushNotifications,
                  (value) => setState(() => _pushNotifications = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Geluid',
                  'Speel geluid bij notificaties',
                  Icons.volume_up,
                  _soundEnabled,
                  (value) => setState(() => _soundEnabled = value),
                  enabled: _pushNotifications,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Trillen',
                  'Laat apparaat trillen',
                  Icons.vibration,
                  _vibrationEnabled,
                  (value) => setState(() => _vibrationEnabled = value),
                  enabled: _pushNotifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data & Sync
          _buildSectionTitle('Data & Synchronisatie'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Automatische Synchronisatie',
                  'Sync data automatisch',
                  Icons.sync,
                  _autoSync,
                  (value) => setState(() => _autoSync = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Offline Modus',
                  'Werk offline wanneer mogelijk',
                  Icons.offline_bolt,
                  _offlineMode,
                  (value) => setState(() => _offlineMode = value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Cache Beheer'),
                  subtitle:
                      const Text('Beheer app cache en tijdelijke bestanden'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _manageCacheSettings(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Performance
          _buildSectionTitle('Prestaties'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Prestatie Instellingen'),
                  subtitle: const Text('Optimaliseer app prestaties'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showPerformanceSettings(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.memory),
                  title: const Text('Geheugen Gebruik'),
                  subtitle: const Text('Bekijk geheugen statistieken'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showMemoryUsage(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Debug Modus'),
                  subtitle: const Text('Ontwikkelaar opties'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showDebugOptions(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Operations
          _buildSectionTitle('Restaurant Operaties'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Bezorging Inschakelen',
                  'Bied bezorgservice aan',
                  Icons.delivery_dining,
                  _enableDelivery,
                  (value) => setState(() => _enableDelivery = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Afhalen Inschakelen',
                  'Bied afhaalservice aan',
                  Icons.takeout_dining,
                  _enableTakeaway,
                  (value) => setState(() => _enableTakeaway = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Reservering Vereist',
                  'Vereist reservering voor bezoek',
                  Icons.event_seat,
                  _requireReservation,
                  (value) => setState(() => _requireReservation = value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu Display
          _buildSectionTitle('Menu Weergave'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Prijzen Tonen',
                  'Toon prijzen op menu',
                  Icons.euro,
                  _showPrices,
                  (value) => setState(() => _showPrices = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Voedingswaarden Tonen',
                  'Toon calorieën en macros',
                  Icons.fitness_center,
                  _showNutrition,
                  (value) => setState(() => _showNutrition = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Allergenen Tonen',
                  'Toon allergen informatie',
                  Icons.warning,
                  _showAllergens,
                  (value) => setState(() => _showAllergens = value),
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  'Standaard Menu Status',
                  'Status voor nieuwe menu items',
                  Icons.restaurant_menu,
                  _defaultMenuStatus,
                  {
                    'active': 'Actief',
                    'inactive': 'Inactief',
                    'draft': 'Concept',
                  },
                  (value) => setState(() => _defaultMenuStatus = value!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Reviews & Ratings
          _buildSectionTitle('Reviews & Beoordelingen'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Gast Reviews Toestaan',
                  'Sta reviews van gasten toe',
                  Icons.rate_review,
                  _allowGuestReviews,
                  (value) => setState(() => _allowGuestReviews = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Auto-goedkeuring Reviews',
                  'Keur reviews automatisch goed',
                  Icons.auto_awesome,
                  _autoApproveReviews,
                  (value) => setState(() => _autoApproveReviews = value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.filter_list),
                  title: const Text('Review Filters'),
                  subtitle: const Text('Configureer review moderatie'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureReviewFilters(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Reservations
          _buildSectionTitle('Reserveringen'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Openingstijden'),
                  subtitle: Text(
                      _businessHours == 'custom' ? 'Aangepast' : 'Standaard'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureBusinessHours(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Max Reservering Vooruit'),
                  subtitle: Text('$_maxReservationDays dagen'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureReservationLimits(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Min Reservering Vooruit'),
                  subtitle: Text('$_minReservationHours uur'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureReservationLimits(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Advanced Business Settings
          _buildSectionTitle('Geavanceerde Instellingen'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Analytics Instellingen'),
                  subtitle: const Text('Configureer business analytics'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureAnalytics(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Voorraad Beheer'),
                  subtitle: const Text('Voorraad tracking instellingen'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureInventory(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.local_offer),
                  title: const Text('Promoties & Aanbiedingen'),
                  subtitle: const Text('Configureer promotie systeem'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configurePromotions(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Notifications
          _buildSectionTitle('Email Notificaties'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Email Notificaties',
                  'Ontvang notificaties via email',
                  Icons.email,
                  _emailNotifications,
                  (value) => setState(() => _emailNotifications = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Dagelijkse Samenvatting',
                  'Ontvang dagelijkse email digest',
                  Icons.summarize,
                  _emailDigest,
                  (value) => setState(() => _emailDigest = value),
                  enabled: _emailNotifications,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Wekelijks Rapport',
                  'Ontvang wekelijks analytics rapport',
                  Icons.assessment,
                  _weeklyReport,
                  (value) => setState(() => _weeklyReport = value),
                  enabled: _emailNotifications,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Maandelijks Rapport',
                  'Ontvang maandelijks business rapport',
                  Icons.calendar_month,
                  _monthlyReport,
                  (value) => setState(() => _monthlyReport = value),
                  enabled: _emailNotifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SMS Notifications
          _buildSectionTitle('SMS Notificaties'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'SMS Notificaties',
                  'Ontvang notificaties via SMS',
                  Icons.sms,
                  _smsNotifications,
                  (value) => setState(() => _smsNotifications = value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Telefoonnummer'),
                  subtitle: const Text('Configureer SMS nummer'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureSmsNumber(),
                  enabled: _smsNotifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Push Notification Types
          _buildSectionTitle('Push Notificatie Types'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Nieuwe Reviews',
                  'Notificaties voor nieuwe reviews',
                  Icons.rate_review,
                  _pushReviews,
                  (value) => setState(() => _pushReviews = value),
                  enabled: _pushNotifications,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Nieuwe Bestellingen',
                  'Notificaties voor nieuwe bestellingen',
                  Icons.shopping_cart,
                  _pushOrders,
                  (value) => setState(() => _pushOrders = value),
                  enabled: _pushNotifications,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Team Updates',
                  'Notificaties voor team wijzigingen',
                  Icons.group,
                  _pushTeam,
                  (value) => setState(() => _pushTeam = value),
                  enabled: _pushNotifications,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Systeem Meldingen',
                  'Notificaties voor systeem updates',
                  Icons.system_update,
                  _pushSystem,
                  (value) => setState(() => _pushSystem = value),
                  enabled: _pushNotifications,
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Marketing Berichten',
                  'Notificaties voor promoties',
                  Icons.campaign,
                  _pushMarketing,
                  (value) => setState(() => _pushMarketing = value),
                  enabled: _pushNotifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quiet Hours
          _buildSectionTitle('Stille Uren'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Stille Uren Inschakelen',
                  'Geen notificaties tijdens stille uren',
                  Icons.bedtime,
                  _quietHoursEnabled,
                  (value) => setState(() => _quietHoursEnabled = value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Start Tijd'),
                  subtitle: Text(_quietHoursStart),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _selectQuietHoursStart(),
                  enabled: _quietHoursEnabled,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time_filled),
                  title: const Text('Eind Tijd'),
                  subtitle: Text(_quietHoursEnd),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _selectQuietHoursEnd(),
                  enabled: _quietHoursEnabled,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Advanced Notification Settings
          _buildSectionTitle('Geavanceerde Instellingen'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Notificatie Prioriteiten'),
                  subtitle: const Text('Configureer prioriteit levels'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureNotificationPriorities(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.group_work),
                  title: const Text('Groepering Instellingen'),
                  subtitle: const Text('Groepeer vergelijkbare notificaties'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureNotificationGrouping(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Notificatie Geschiedenis'),
                  subtitle: const Text('Beheer notificatie historie'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureNotificationHistory(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Security
          _buildSectionTitle('Account Beveiliging'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Twee-Factor Authenticatie',
                  'Extra beveiliging voor je account',
                  Icons.security,
                  _twoFactorAuth,
                  (value) => setState(() => _twoFactorAuth = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Login Notificaties',
                  'Notificaties bij nieuwe logins',
                  Icons.login,
                  _loginNotifications,
                  (value) => setState(() => _loginNotifications = value),
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  'Sessie Time-out',
                  'Automatisch uitloggen na inactiviteit',
                  Icons.timer,
                  _sessionTimeout,
                  {
                    '15_minutes': '15 minuten',
                    '30_minutes': '30 minuten',
                    '1_hour': '1 uur',
                    '4_hours': '4 uur',
                    '24_hours': '24 uur',
                    'never': 'Nooit',
                  },
                  (value) => setState(() => _sessionTimeout = value!),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Wachtwoord Wijzigen'),
                  subtitle: const Text('Wijzig je account wachtwoord'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _changePassword(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Privacy
          _buildSectionTitle('Data Privacy'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Data Verzameling',
                  'Sta data verzameling toe voor verbetering',
                  Icons.data_usage,
                  _dataCollection,
                  (value) => setState(() => _dataCollection = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Analytics Tracking',
                  'Sta analytics tracking toe',
                  Icons.analytics,
                  _analyticsTracking,
                  (value) => setState(() => _analyticsTracking = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Marketing Cookies',
                  'Sta marketing cookies toe',
                  Icons.cookie,
                  _marketingCookies,
                  (value) => setState(() => _marketingCookies = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Data Delen',
                  'Deel geanonimiseerde data met partners',
                  Icons.share,
                  _shareData,
                  (value) => setState(() => _shareData = value),
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  'Data Bewaring',
                  'Hoe lang data bewaren',
                  Icons.storage,
                  _dataRetention,
                  {
                    '1_year': '1 jaar',
                    '2_years': '2 jaar',
                    '5_years': '5 jaar',
                    'indefinite': 'Onbeperkt',
                  },
                  (value) => setState(() => _dataRetention = value!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Privacy Controls
          _buildSectionTitle('Privacy Controles'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Data Exporteren'),
                  subtitle: const Text('Download al je persoonlijke data'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _exportPersonalData(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Privacy Dashboard'),
                  subtitle: const Text('Bekijk wat we over je weten'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showPrivacyDashboard(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Data Verwijdering'),
                  subtitle: const Text('Verwijder specifieke data'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _manageDataDeletion(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel),
                  title: const Text('Privacy Beleid'),
                  subtitle: const Text('Lees ons privacy beleid'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showPrivacyPolicy(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // GDPR Compliance
          _buildSectionTitle('GDPR Compliance'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text('GDPR Rechten'),
                  subtitle: const Text('Bekijk je GDPR rechten'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showGdprRights(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.contact_support),
                  title: const Text('Data Protection Officer'),
                  subtitle: const Text('Contact DPO voor privacy vragen'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _contactDpo(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text('Privacy Klacht'),
                  subtitle: const Text('Dien een privacy klacht in'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _filePrivacyComplaint(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // External Services
          _buildSectionTitle('Externe Services'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Google Maps',
                  'Gebruik Google Maps voor locaties',
                  Icons.map,
                  _googleMapsEnabled,
                  (value) => setState(() => _googleMapsEnabled = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'MyFitnessPal',
                  'Integratie met MyFitnessPal',
                  Icons.fitness_center,
                  _myFitnessPalEnabled,
                  (value) => setState(() => _myFitnessPalEnabled = value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.api),
                  title: const Text('API Instellingen'),
                  subtitle: const Text('Configureer externe API\'s'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureApiSettings(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Analytics & Tracking
          _buildSectionTitle('Analytics & Tracking'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Google Analytics',
                  'Gebruik Google Analytics tracking',
                  Icons.analytics,
                  _googleAnalyticsEnabled,
                  (value) => setState(() => _googleAnalyticsEnabled = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Facebook Pixel',
                  'Gebruik Facebook Pixel tracking',
                  Icons.facebook,
                  _facebookPixelEnabled,
                  (value) => setState(() => _facebookPixelEnabled = value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.track_changes),
                  title: const Text('Custom Tracking'),
                  subtitle: const Text('Configureer aangepaste tracking'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureCustomTracking(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment & Communication
          _buildSectionTitle('Betalingen & Communicatie'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildDropdownTile(
                  'Betaal Provider',
                  'Kies je betaal service',
                  Icons.payment,
                  _paymentProvider,
                  {
                    'stripe': 'Stripe',
                    'paypal': 'PayPal',
                    'mollie': 'Mollie',
                    'adyen': 'Adyen',
                  },
                  (value) => setState(() => _paymentProvider = value!),
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  'Email Provider',
                  'Kies je email service',
                  Icons.email,
                  _emailProvider,
                  {
                    'sendgrid': 'SendGrid',
                    'mailgun': 'Mailgun',
                    'ses': 'Amazon SES',
                    'smtp': 'Custom SMTP',
                  },
                  (value) => setState(() => _emailProvider = value!),
                ),
                const Divider(height: 1),
                _buildDropdownTile(
                  'SMS Provider',
                  'Kies je SMS service',
                  Icons.sms,
                  _smsProvider,
                  {
                    'twilio': 'Twilio',
                    'messagebird': 'MessageBird',
                    'nexmo': 'Vonage (Nexmo)',
                    'custom': 'Custom SMS',
                  },
                  (value) => setState(() => _smsProvider = value!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Webhooks & API
          _buildSectionTitle('Webhooks & API'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.webhook),
                  title: const Text('Webhooks'),
                  subtitle: const Text('Configureer webhook endpoints'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureWebhooks(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('API Keys'),
                  subtitle: const Text('Beheer API sleutels'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _manageApiKeys(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.rate_limit),
                  title: const Text('Rate Limiting'),
                  subtitle: const Text('Configureer API limieten'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureRateLimiting(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Third-party Integrations
          _buildSectionTitle('Derde Partij Integraties'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('POS Systemen'),
                  subtitle: const Text('Integreer met kassasystemen'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configurePosIntegrations(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: const Text('Voorraad Systemen'),
                  subtitle: const Text('Koppel voorraad management'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureInventoryIntegrations(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: const Text('Boekhouding'),
                  subtitle: const Text('Integreer met boekhoudsoftware'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureAccountingIntegrations(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? (value ? AppColors.primary : null) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? AppColors.textSecondary : Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.primary,
      ),
      onTap: enabled ? () => onChanged(!value) : null,
    );
  }

  Widget _buildDropdownTile<T>(
    String title,
    String subtitle,
    IconData icon,
    T value,
    Map<T, String> options,
    ValueChanged<T?> onChanged, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? AppColors.primary : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? AppColors.textSecondary : Colors.grey,
        ),
      ),
      trailing: DropdownButton<T>(
        value: value,
        onChanged: enabled ? onChanged : null,
        items: options.entries.map((entry) {
          return DropdownMenuItem<T>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        underline: Container(),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final settingsData = {
        // App Settings
        'dark_mode': _darkMode,
        'push_notifications': _pushNotifications,
        'sound_enabled': _soundEnabled,
        'vibration_enabled': _vibrationEnabled,
        'auto_sync': _autoSync,
        'offline_mode': _offlineMode,
        'language': _language,
        'currency': _currency,
        'date_format': _dateFormat,
        'time_format': _timeFormat,
        'theme': _theme,

        // Business Settings
        'auto_approve_reviews': _autoApproveReviews,
        'allow_guest_reviews': _allowGuestReviews,
        'require_reservation': _requireReservation,
        'enable_delivery': _enableDelivery,
        'enable_takeaway': _enableTakeaway,
        'show_prices': _showPrices,
        'show_nutrition': _showNutrition,
        'show_allergens': _showAllergens,
        'default_menu_status': _defaultMenuStatus,
        'business_hours': _businessHours,
        'max_reservation_days': _maxReservationDays,
        'min_reservation_hours': _minReservationHours,

        // Notification Settings
        'email_notifications': _emailNotifications,
        'sms_notifications': _smsNotifications,
        'push_reviews': _pushReviews,
        'push_orders': _pushOrders,
        'push_team': _pushTeam,
        'push_system': _pushSystem,
        'push_marketing': _pushMarketing,
        'email_digest': _emailDigest,
        'weekly_report': _weeklyReport,
        'monthly_report': _monthlyReport,
        'quiet_hours_start': _quietHoursStart,
        'quiet_hours_end': _quietHoursEnd,
        'quiet_hours_enabled': _quietHoursEnabled,

        // Privacy & Security Settings
        'two_factor_auth': _twoFactorAuth,
        'login_notifications': _loginNotifications,
        'data_collection': _dataCollection,
        'analytics_tracking': _analyticsTracking,
        'marketing_cookies': _marketingCookies,
        'share_data': _shareData,
        'data_retention': _dataRetention,
        'session_timeout': _sessionTimeout,

        // Integration Settings
        'google_maps_enabled': _googleMapsEnabled,
        'myfitnesspal_enabled': _myFitnessPalEnabled,
        'google_analytics_enabled': _googleAnalyticsEnabled,
        'facebook_pixel_enabled': _facebookPixelEnabled,
        'payment_provider': _paymentProvider,
        'email_provider': _emailProvider,
        'sms_provider': _smsProvider,
      };

      await _apiService.updateSettings(settingsData);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instellingen opgeslagen'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opslaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetDefaultsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Standaard Instellingen'),
        content: const Text(
            'Weet je zeker dat je alle instellingen wilt terugzetten naar de standaardwaarden? Deze actie kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefaults();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Terugzetten'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      // Reset all settings to default values
      _darkMode = false;
      _pushNotifications = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _autoSync = true;
      _offlineMode = false;
      _language = 'nl';
      _currency = 'EUR';
      _dateFormat = 'dd/MM/yyyy';
      _timeFormat = '24h';
      _theme = 'system';

      _autoApproveReviews = false;
      _allowGuestReviews = true;
      _requireReservation = false;
      _enableDelivery = false;
      _enableTakeaway = true;
      _showPrices = true;
      _showNutrition = true;
      _showAllergens = true;
      _defaultMenuStatus = 'active';
      _businessHours = 'custom';
      _maxReservationDays = 30;
      _minReservationHours = 2;

      _emailNotifications = true;
      _smsNotifications = false;
      _pushReviews = true;
      _pushOrders = true;
      _pushTeam = true;
      _pushSystem = true;
      _pushMarketing = false;
      _emailDigest = true;
      _weeklyReport = true;
      _monthlyReport = true;
      _quietHoursStart = '22:00';
      _quietHoursEnd = '08:00';
      _quietHoursEnabled = false;

      _twoFactorAuth = false;
      _loginNotifications = true;
      _dataCollection = true;
      _analyticsTracking = true;
      _marketingCookies = false;
      _shareData = false;
      _dataRetention = '2_years';
      _sessionTimeout = '30_minutes';

      _googleMapsEnabled = true;
      _myFitnessPalEnabled = true;
      _googleAnalyticsEnabled = false;
      _facebookPixelEnabled = false;
      _paymentProvider = 'stripe';
      _emailProvider = 'sendgrid';
      _smsProvider = 'twilio';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Instellingen teruggezet naar standaardwaarden'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Placeholder methods for various settings actions
  void _exportSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Export functionaliteit wordt binnenkort toegevoegd')),
    );
  }

  void _importSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Import functionaliteit wordt binnenkort toegevoegd')),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache gewist')),
    );
  }

  void _manageCacheSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache beheer wordt binnenkort toegevoegd')),
    );
  }

  void _showPerformanceSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Prestatie instellingen worden binnenkort toegevoegd')),
    );
  }

  void _showMemoryUsage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Geheugen statistieken worden binnenkort toegevoegd')),
    );
  }

  void _showDebugOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Debug opties worden binnenkort toegevoegd')),
    );
  }

  void _configureBusinessHours() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Openingstijden configuratie wordt binnenkort toegevoegd')),
    );
  }

  void _configureReservationLimits() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Reservering limieten worden binnenkort toegevoegd')),
    );
  }

  void _configureReviewFilters() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Review filters worden binnenkort toegevoegd')),
    );
  }

  void _configureAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Analytics configuratie wordt binnenkort toegevoegd')),
    );
  }

  void _configureInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Voorraad configuratie wordt binnenkort toegevoegd')),
    );
  }

  void _configurePromotions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Promotie configuratie wordt binnenkort toegevoegd')),
    );
  }

  void _configureSmsNumber() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('SMS nummer configuratie wordt binnenkort toegevoegd')),
    );
  }

  void _selectQuietHoursStart() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_quietHoursStart.split(':')[0]),
        minute: int.parse(_quietHoursStart.split(':')[1]),
      ),
    );

    if (time != null) {
      setState(() {
        _quietHoursStart =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _selectQuietHoursEnd() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_quietHoursEnd.split(':')[0]),
        minute: int.parse(_quietHoursEnd.split(':')[1]),
      ),
    );

    if (time != null) {
      setState(() {
        _quietHoursEnd =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _configureNotificationPriorities() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Notificatie prioriteiten worden binnenkort toegevoegd')),
    );
  }

  void _configureNotificationGrouping() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Notificatie groepering wordt binnenkort toegevoegd')),
    );
  }

  void _configureNotificationHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Notificatie geschiedenis wordt binnenkort toegevoegd')),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Wachtwoord wijzigen wordt binnenkort toegevoegd')),
    );
  }

  void _exportPersonalData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export wordt binnenkort toegevoegd')),
    );
  }

  void _showPrivacyDashboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Privacy dashboard wordt binnenkort toegevoegd')),
    );
  }

  void _manageDataDeletion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Data verwijdering wordt binnenkort toegevoegd')),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Privacy beleid wordt binnenkort toegevoegd')),
    );
  }

  void _showGdprRights() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('GDPR rechten worden binnenkort toegevoegd')),
    );
  }

  void _contactDpo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('DPO contact wordt binnenkort toegevoegd')),
    );
  }

  void _filePrivacyComplaint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Privacy klacht indienen wordt binnenkort toegevoegd')),
    );
  }

  void _configureApiSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('API instellingen worden binnenkort toegevoegd')),
    );
  }

  void _configureCustomTracking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Custom tracking wordt binnenkort toegevoegd')),
    );
  }

  void _configureWebhooks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Webhook configuratie wordt binnenkort toegevoegd')),
    );
  }

  void _manageApiKeys() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('API key beheer wordt binnenkort toegevoegd')),
    );
  }

  void _configureRateLimiting() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Rate limiting wordt binnenkort toegevoegd')),
    );
  }

  void _configurePosIntegrations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('POS integraties worden binnenkort toegevoegd')),
    );
  }

  void _configureInventoryIntegrations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Voorraad integraties worden binnenkort toegevoegd')),
    );
  }

  void _configureAccountingIntegrations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Boekhoud integraties worden binnenkort toegevoegd')),
    );
  }
}
