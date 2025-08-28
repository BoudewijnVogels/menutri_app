import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CateraarProfileManagementPage extends ConsumerStatefulWidget {
  const CateraarProfileManagementPage({super.key});

  @override
  ConsumerState<CateraarProfileManagementPage> createState() =>
      _CateraarProfileManagementPageState();
}

class _CateraarProfileManagementPageState
    extends ConsumerState<CateraarProfileManagementPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;

  // Form controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _vatNumberController = TextEditingController();
  final TextEditingController _chamberOfCommerceController =
      TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();

  // Personal profile controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _personalEmailController =
      TextEditingController();
  final TextEditingController _personalPhoneController =
      TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _businessData = {};
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _teamMembers = [];
  String? _profileImagePath;
  String? _companyLogoPath;

  final List<String> _cuisineTypes = [
    'Italiaans',
    'Frans',
    'Chinees',
    'Japans',
    'Indiaas',
    'Mexicaans',
    'Grieks',
    'Thais',
    'Amerikaans',
    'Mediterraans',
    'Vegetarisch',
    'Veganistisch',
    'Glutenvrij',
    'Biologisch',
    'Fast Food',
    'Fine Dining'
  ];

  final List<String> _businessTypes = [
    'Restaurant',
    'Café',
    'Bar',
    'Bakkerij',
    'Catering',
    'Food Truck',
    'Pizzeria',
    'Snackbar',
    'Hotel Restaurant',
    'Brasserie'
  ];

  List<String> _selectedCuisineTypes = [];
  String _selectedBusinessType = 'Restaurant';
  String _selectedLanguage = 'nl';
  String _selectedTimezone = 'Europe/Amsterdam';
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _marketingEmails = false;
  bool _publicProfile = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyNameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _vatNumberController.dispose();
    _chamberOfCommerceController.dispose();
    _bankAccountController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _personalEmailController.dispose();
    _personalPhoneController.dispose();
    _jobTitleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final profileResponse = await _apiService.getCurrentUser();
      final businessResponse = await _apiService.getBusinessProfile();
      final teamResponse =
          await _apiService.getTeamMembers(_businessData['id']);

      final profile = profileResponse['profile'] ?? {};
      final business = businessResponse['business'] ?? {};
      final team =
          List<Map<String, dynamic>>.from(teamResponse['members'] ?? []);

      setState(() {
        _profileData = profile;
        _businessData = business;
        _teamMembers = team;
        _isLoading = false;
      });

      _populateControllers();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden profiel: $e')),
        );
      }
    }
  }

  void _populateControllers() {
    // Business data
    _companyNameController.text = _businessData['company_name'] ?? '';
    _descriptionController.text = _businessData['description'] ?? '';
    _websiteController.text = _businessData['website'] ?? '';
    _phoneController.text = _businessData['phone'] ?? '';
    _emailController.text = _businessData['email'] ?? '';
    _addressController.text = _businessData['address'] ?? '';
    _cityController.text = _businessData['city'] ?? '';
    _postalCodeController.text = _businessData['postal_code'] ?? '';
    _countryController.text = _businessData['country'] ?? 'Nederland';
    _vatNumberController.text = _businessData['vat_number'] ?? '';
    _chamberOfCommerceController.text =
        _businessData['chamber_of_commerce'] ?? '';
    _bankAccountController.text = _businessData['bank_account'] ?? '';

    // Personal data
    _firstNameController.text = _profileData['first_name'] ?? '';
    _lastNameController.text = _profileData['last_name'] ?? '';
    _personalEmailController.text = _profileData['email'] ?? '';
    _personalPhoneController.text = _profileData['phone'] ?? '';
    _jobTitleController.text = _profileData['job_title'] ?? '';
    _bioController.text = _profileData['bio'] ?? '';

    // Settings
    _selectedCuisineTypes =
        List<String>.from(_businessData['cuisine_types'] ?? []);
    _selectedBusinessType = _businessData['business_type'] ?? 'Restaurant';
    _selectedLanguage = _profileData['language'] ?? 'nl';
    _selectedTimezone = _profileData['timezone'] ?? 'Europe/Amsterdam';
    _emailNotifications = _profileData['email_notifications'] ?? true;
    _smsNotifications = _profileData['sms_notifications'] ?? false;
    _marketingEmails = _profileData['marketing_emails'] ?? false;
    _publicProfile = _businessData['public_profile'] ?? true;

    _profileImagePath = _profileData['profile_image'];
    _companyLogoPath = _businessData['logo'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profiel Beheer'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveProfile,
            tooltip: 'Opslaan',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export_profile':
                  _exportProfile();
                  break;
                case 'backup_data':
                  _backupData();
                  break;
                case 'delete_account':
                  _showDeleteAccountDialog();
                  break;
                case 'privacy_settings':
                  _showPrivacySettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_profile',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Profiel Exporteren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'backup_data',
                child: ListTile(
                  leading: Icon(Icons.backup),
                  title: Text('Data Backup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'privacy_settings',
                child: ListTile(
                  leading: Icon(Icons.privacy_tip),
                  title: Text('Privacy Instellingen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete_account',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Account Verwijderen',
                      style: TextStyle(color: Colors.red)),
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
              Tab(text: 'Persoonlijk'),
              Tab(text: 'Bedrijf'),
              Tab(text: 'Team'),
              Tab(text: 'Statistieken'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalTab(),
                _buildBusinessTab(),
                _buildTeamTab(),
                _buildStatisticsTab(),
              ],
            ),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          _buildProfileHeader(),

          const SizedBox(height: 24),

          // Personal information
          _buildSectionTitle('Persoonlijke Informatie'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Voornaam',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Achternaam',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _jobTitleController,
            decoration: const InputDecoration(
              labelText: 'Functietitel',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio / Beschrijving',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              hintText: 'Vertel iets over jezelf...',
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          // Contact information
          _buildSectionTitle('Contactgegevens'),
          const SizedBox(height: 16),

          TextFormField(
            controller: _personalEmailController,
            decoration: const InputDecoration(
              labelText: 'Email Adres',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _personalPhoneController,
            decoration: const InputDecoration(
              labelText: 'Telefoonnummer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 24),

          // Preferences
          _buildSectionTitle('Voorkeuren'),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Taal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.language),
            ),
            items: const [
              DropdownMenuItem(value: 'nl', child: Text('Nederlands')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'de', child: Text('Deutsch')),
              DropdownMenuItem(value: 'fr', child: Text('Français')),
              DropdownMenuItem(value: 'es', child: Text('Español')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedTimezone,
            decoration: const InputDecoration(
              labelText: 'Tijdzone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time),
            ),
            items: const [
              DropdownMenuItem(
                  value: 'Europe/Amsterdam', child: Text('Amsterdam (CET)')),
              DropdownMenuItem(
                  value: 'Europe/London', child: Text('London (GMT)')),
              DropdownMenuItem(
                  value: 'America/New_York', child: Text('New York (EST)')),
              DropdownMenuItem(
                  value: 'America/Los_Angeles',
                  child: Text('Los Angeles (PST)')),
              DropdownMenuItem(value: 'Asia/Tokyo', child: Text('Tokyo (JST)')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTimezone = value!;
              });
            },
          ),

          const SizedBox(height: 24),

          // Notification preferences
          _buildSectionTitle('Notificatie Voorkeuren'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Email Notificaties'),
                  subtitle: const Text('Ontvang notificaties via email'),
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                  secondary: const Icon(Icons.email),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('SMS Notificaties'),
                  subtitle: const Text('Ontvang notificaties via SMS'),
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() {
                      _smsNotifications = value;
                    });
                  },
                  secondary: const Icon(Icons.sms),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Marketing Emails'),
                  subtitle: const Text('Ontvang marketing en promotie emails'),
                  value: _marketingEmails,
                  onChanged: (value) {
                    setState(() {
                      _marketingEmails = value;
                    });
                  },
                  secondary: const Icon(Icons.campaign),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company logo
          _buildCompanyLogoSection(),

          const SizedBox(height: 24),

          // Company information
          _buildSectionTitle('Bedrijfsinformatie'),
          const SizedBox(height: 16),

          TextFormField(
            controller: _companyNameController,
            decoration: const InputDecoration(
              labelText: 'Bedrijfsnaam',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedBusinessType,
            decoration: const InputDecoration(
              labelText: 'Bedrijfstype',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: _businessTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBusinessType = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Beschrijving',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              hintText: 'Beschrijf je bedrijf...',
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(
              labelText: 'Website',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.web),
              hintText: 'https://www.example.com',
            ),
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 24),

          // Cuisine types
          _buildSectionTitle('Keuken Types'),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cuisineTypes.map((cuisine) {
              final isSelected = _selectedCuisineTypes.contains(cuisine);
              return FilterChip(
                label: Text(cuisine),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCuisineTypes.add(cuisine);
                    } else {
                      _selectedCuisineTypes.remove(cuisine);
                    }
                  });
                },
                backgroundColor: AppColors.background,
                selectedColor:
                    AppColors.withAlphaFraction(AppColors.primary, 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Contact information
          _buildSectionTitle('Contactgegevens'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefoonnummer',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Address information
          _buildSectionTitle('Adresgegevens'),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Adres',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Stad',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Postcode',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _countryController,
            decoration: const InputDecoration(
              labelText: 'Land',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.public),
            ),
          ),

          const SizedBox(height: 24),

          // Business details
          _buildSectionTitle('Bedrijfsgegevens'),
          const SizedBox(height: 16),

          TextFormField(
            controller: _vatNumberController,
            decoration: const InputDecoration(
              labelText: 'BTW Nummer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt),
              hintText: 'NL123456789B01',
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _chamberOfCommerceController,
            decoration: const InputDecoration(
              labelText: 'KvK Nummer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business_center),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _bankAccountController,
            decoration: const InputDecoration(
              labelText: 'IBAN',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance),
              hintText: 'NL91 ABNA 0417 1643 00',
            ),
          ),

          const SizedBox(height: 24),

          // Privacy settings
          _buildSectionTitle('Privacy Instellingen'),
          const SizedBox(height: 16),

          Card(
            child: SwitchListTile(
              title: const Text('Openbaar Profiel'),
              subtitle:
                  const Text('Maak je bedrijfsprofiel zichtbaar voor gasten'),
              value: _publicProfile,
              onChanged: (value) {
                setState(() {
                  _publicProfile = value;
                });
              },
              secondary: const Icon(Icons.public),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team overview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Leden (${_teamMembers.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => _inviteTeamMember(),
                icon: const Icon(Icons.person_add),
                label: const Text('Uitnodigen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Team members list
          if (_teamMembers.isEmpty)
            _buildEmptyTeamState()
          else
            ..._teamMembers.map((member) => _buildTeamMemberCard(member)),

          const SizedBox(height: 24),

          // Team settings
          _buildSectionTitle('Team Instellingen'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Rollen & Rechten'),
                  subtitle: const Text('Beheer team rollen en toegangsrechten'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _manageRolesAndPermissions(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Team Notificaties'),
                  subtitle:
                      const Text('Configureer team notificatie instellingen'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _configureTeamNotifications(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Activiteiten Log'),
                  subtitle: const Text('Bekijk team activiteiten geschiedenis'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _viewTeamActivityLog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile statistics
          _buildSectionTitle('Profiel Statistieken'),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Profiel Weergaven',
                (_statistics['profile_views'] ?? 0).toString(),
                Icons.visibility,
                Colors.blue,
              ),
              _buildStatCard(
                'Restaurants',
                (_statistics['restaurant_count'] ?? 0).toString(),
                Icons.restaurant,
                Colors.green,
              ),
              _buildStatCard(
                'Menu Items',
                (_statistics['menu_items_count'] ?? 0).toString(),
                Icons.restaurant_menu,
                Colors.orange,
              ),
              _buildStatCard(
                'Team Leden',
                _teamMembers.length.toString(),
                Icons.group,
                Colors.purple,
              ),
              _buildStatCard(
                'Reviews',
                (_statistics['reviews_count'] ?? 0).toString(),
                Icons.star,
                Colors.amber,
              ),
              _buildStatCard(
                'Gemiddelde Rating',
                (_statistics['average_rating'] ?? 0.0).toStringAsFixed(1),
                Icons.star_rate,
                Colors.yellow,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Account information
          _buildSectionTitle('Account Informatie'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Lid sinds'),
                  subtitle: Text(_formatDate(_profileData['created_at'])),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('Laatst bijgewerkt'),
                  subtitle: Text(_formatDate(_profileData['updated_at'])),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified),
                  title: const Text('Account Status'),
                  subtitle: Text(_profileData['is_verified'] == true
                      ? 'Geverifieerd'
                      : 'Niet geverifieerd'),
                  trailing: _profileData['is_verified'] == true
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.warning, color: Colors.orange),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.workspace_premium),
                  title: const Text('Abonnement'),
                  subtitle: Text(_profileData['subscription_type'] ?? 'Gratis'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _manageSubscription(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data & Privacy
          _buildSectionTitle('Data & Privacy'),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Data Exporteren'),
                  subtitle: const Text('Download al je gegevens'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _exportData(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Data Backup'),
                  subtitle: const Text('Maak een backup van je gegevens'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _backupData(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Instellingen'),
                  subtitle: const Text('Beheer je privacy voorkeuren'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showPrivacySettings(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Account Verwijderen',
                      style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Permanent je account verwijderen'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.red),
                  onTap: () => _showDeleteAccountDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile image
            GestureDetector(
              onTap: () => _changeProfileImage(),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        AppColors.withAlphaFraction(AppColors.primary, 0.2),
                    backgroundImage: _profileImagePath != null
                        ? NetworkImage(_profileImagePath!)
                        : null,
                    child: _profileImagePath == null
                        ? Text(
                            _getInitials(
                                '${_firstNameController.text} ${_lastNameController.text}'),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_firstNameController.text} ${_lastNameController.text}'
                            .trim()
                            .isEmpty
                        ? 'Naam niet ingesteld'
                        : '${_firstNameController.text} ${_lastNameController.text}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _jobTitleController.text.isEmpty
                        ? 'Functietitel niet ingesteld'
                        : _jobTitleController.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _profileData['is_verified'] == true
                            ? Icons.verified
                            : Icons.warning,
                        size: 16,
                        color: _profileData['is_verified'] == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _profileData['is_verified'] == true
                            ? 'Geverifieerd'
                            : 'Niet geverifieerd',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _profileData['is_verified'] == true
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyLogoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bedrijfslogo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Company logo
                GestureDetector(
                  onTap: () => _changeCompanyLogo(),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color:
                          AppColors.withAlphaFraction(AppColors.primary, 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            AppColors.withAlphaFraction(AppColors.primary, 0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _companyLogoPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _companyLogoPath!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.add_photo_alternate,
                            color: AppColors.primary,
                            size: 32,
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _companyNameController.text.isEmpty
                            ? 'Bedrijfsnaam niet ingesteld'
                            : _companyNameController.text,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedBusinessType,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _changeCompanyLogo(),
                        icon: const Icon(Icons.upload),
                        label: Text(
                            _companyLogoPath != null ? 'Wijzigen' : 'Uploaden'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.withAlphaFraction(AppColors.primary, 0.2),
          backgroundImage:
              member['avatar'] != null ? NetworkImage(member['avatar']) : null,
          child: member['avatar'] == null
              ? Text(
                  _getInitials(member['name'] ?? ''),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(member['name'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member['role'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  member['is_active'] == true
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 12,
                  color:
                      member['is_active'] == true ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  member['is_active'] == true ? 'Actief' : 'Inactief',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: member['is_active'] == true
                            ? Colors.green
                            : Colors.grey,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleTeamMemberAction(value, member),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Bewerken'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'permissions',
              child: ListTile(
                leading: Icon(Icons.security),
                title: Text('Rechten'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: member['is_active'] == true ? 'deactivate' : 'activate',
              child: ListTile(
                leading: Icon(member['is_active'] == true
                    ? Icons.block
                    : Icons.check_circle),
                title: Text(
                    member['is_active'] == true ? 'Deactiveren' : 'Activeren'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red),
                title: Text('Verwijderen', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTeamState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.group_add,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nog geen teamleden',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nodig teamleden uit om samen te werken',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _inviteTeamMember(),
              icon: const Icon(Icons.person_add),
              label: const Text('Eerste Teamlid Uitnodigen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  Future<void> _changeProfileImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      try {
        final response = await _apiService.uploadProfileImage(image.path);
        setState(() {
          _profileImagePath = response['image_url'];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profielfoto bijgewerkt'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout bij uploaden foto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeCompanyLogo() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      try {
        final response = await _apiService.uploadCompanyLogo(image.path);
        setState(() {
          _companyLogoPath = response['logo_url'];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bedrijfslogo bijgewerkt'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout bij uploaden logo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      // Prepare profile data
      final profileData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _personalEmailController.text,
        'phone': _personalPhoneController.text,
        'job_title': _jobTitleController.text,
        'bio': _bioController.text,
        'language': _selectedLanguage,
        'timezone': _selectedTimezone,
        'email_notifications': _emailNotifications,
        'sms_notifications': _smsNotifications,
        'marketing_emails': _marketingEmails,
      };

      // Prepare business data
      final businessData = {
        'company_name': _companyNameController.text,
        'business_type': _selectedBusinessType,
        'description': _descriptionController.text,
        'website': _websiteController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'postal_code': _postalCodeController.text,
        'country': _countryController.text,
        'vat_number': _vatNumberController.text,
        'chamber_of_commerce': _chamberOfCommerceController.text,
        'bank_account': _bankAccountController.text,
        'cuisine_types': _selectedCuisineTypes,
        'public_profile': _publicProfile,
      };

      // Save to API
      await _apiService.updateProfile(profileData);
      await _apiService.updateBusinessProfile(businessData);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profiel opgeslagen'),
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

  void _inviteTeamMember() {
    // Navigate to team invitation page or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Team uitnodiging functionaliteit wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _handleTeamMemberAction(String action, Map<String, dynamic> member) {
    switch (action) {
      case 'edit':
        // Edit team member
        break;
      case 'permissions':
        // Manage permissions
        break;
      case 'activate':
      case 'deactivate':
        // Toggle active status
        break;
      case 'remove':
        // Remove team member
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action functionaliteit wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _manageRolesAndPermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rollen & rechten beheer wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _configureTeamNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Team notificatie instellingen worden binnenkort toegevoegd'),
      ),
    );
  }

  void _viewTeamActivityLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team activiteiten log wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _manageSubscription() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abonnement beheer wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _exportProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profiel export wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _backupData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data backup wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Instellingen'),
        content:
            const Text('Privacy instellingen worden binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Verwijderen'),
        content: const Text(
            'Weet je zeker dat je je account permanent wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Account verwijdering wordt binnenkort toegevoegd'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'Onbekend';

    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateTime;
    }
  }
}
