import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CateraarPromotionsPage extends ConsumerStatefulWidget {
  const CateraarPromotionsPage({super.key});

  @override
  ConsumerState<CateraarPromotionsPage> createState() =>
      _CateraarPromotionsPageState();
}

class _CateraarPromotionsPageState extends ConsumerState<CateraarPromotionsPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _promotions = [];
  List<Map<String, dynamic>> _filteredPromotions = [];
  List<Map<String, dynamic>> _campaigns = [];
  List<Map<String, dynamic>> _templates = [];

  String _selectedStatus = 'all';
  String _selectedType = 'all';
  String _sortBy = 'created_date';
  bool _sortAscending = false;

  final Map<String, String> _statusOptions = {
    'all': 'Alle',
    'draft': 'Concept',
    'scheduled': 'Ingepland',
    'active': 'Actief',
    'paused': 'Gepauzeerd',
    'completed': 'Voltooid',
    'expired': 'Verlopen',
  };

  final Map<String, String> _typeOptions = {
    'all': 'Alle Types',
    'discount': 'Korting',
    'happy_hour': 'Happy Hour',
    'loyalty': 'Loyaliteit',
    'seasonal': 'Seizoen',
    'new_customer': 'Nieuwe Klant',
    'referral': 'Doorverwijzing',
  };

  final Map<String, String> _sortOptions = {
    'created_date': 'Aanmaakdatum',
    'start_date': 'Startdatum',
    'end_date': 'Einddatum',
    'name': 'Naam',
    'performance': 'Prestatie',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPromotionsData();
    _searchController.addListener(_filterPromotions);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotionsData() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getPromotionsData();

      setState(() {
        _promotions =
            List<Map<String, dynamic>>.from(response['promotions'] ?? []);
        _campaigns =
            List<Map<String, dynamic>>.from(response['campaigns'] ?? []);
        _templates =
            List<Map<String, dynamic>>.from(response['templates'] ?? []);
        _isLoading = false;
      });

      _filterPromotions();
    } catch (e) {
      setState(() {
        _promotions = _getDefaultPromotions();
        _campaigns = _getDefaultCampaigns();
        _templates = _getDefaultTemplates();
        _isLoading = false;
      });
      _filterPromotions();
    }
  }

  List<Map<String, dynamic>> _getDefaultPromotions() {
    return [
      {
        'id': '1',
        'name': 'Zomer Happy Hour',
        'type': 'happy_hour',
        'status': 'active',
        'discount_type': 'percentage',
        'discount_value': 25,
        'start_date': '2024-01-01',
        'end_date': '2024-01-31',
        'description': '25% korting op alle dranken tussen 17:00-19:00',
        'conditions': 'Geldig van maandag t/m vrijdag',
        'usage_count': 156,
        'usage_limit': 500,
        'revenue_impact': 2340.50,
        'created_date': '2023-12-15',
        'restaurants': ['1', '2'],
        'menu_items': ['drinks'],
        'time_restrictions': '17:00-19:00',
        'day_restrictions': [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday'
        ],
      },
      {
        'id': '2',
        'name': 'Nieuwe Klant Welkom',
        'type': 'new_customer',
        'status': 'active',
        'discount_type': 'fixed',
        'discount_value': 10,
        'start_date': '2024-01-01',
        'end_date': '2024-12-31',
        'description': '€10 korting voor nieuwe klanten',
        'conditions': 'Minimale bestelling €30',
        'usage_count': 89,
        'usage_limit': null,
        'revenue_impact': 1890.00,
        'created_date': '2023-12-01',
        'restaurants': ['1'],
        'menu_items': [],
        'min_order_value': 30,
      },
      {
        'id': '3',
        'name': 'Weekend Special',
        'type': 'seasonal',
        'status': 'scheduled',
        'discount_type': 'percentage',
        'discount_value': 15,
        'start_date': '2024-02-01',
        'end_date': '2024-02-29',
        'description': '15% korting op hoofdgerechten in het weekend',
        'conditions': 'Alleen zaterdag en zondag',
        'usage_count': 0,
        'usage_limit': 200,
        'revenue_impact': 0,
        'created_date': '2024-01-10',
        'restaurants': ['1', '2', '3'],
        'menu_items': ['main_courses'],
        'day_restrictions': ['saturday', 'sunday'],
      },
      {
        'id': '4',
        'name': 'Loyaliteit Bonus',
        'type': 'loyalty',
        'status': 'paused',
        'discount_type': 'percentage',
        'discount_value': 20,
        'start_date': '2023-11-01',
        'end_date': '2024-01-31',
        'description': '20% korting voor trouwe klanten',
        'conditions': 'Minimaal 5 bezoeken in de afgelopen maand',
        'usage_count': 234,
        'usage_limit': 1000,
        'revenue_impact': 4680.00,
        'created_date': '2023-10-15',
        'restaurants': ['1', '2'],
        'menu_items': [],
        'min_visits': 5,
      },
      {
        'id': '5',
        'name': 'Kerst Actie',
        'type': 'seasonal',
        'status': 'completed',
        'discount_type': 'fixed',
        'discount_value': 5,
        'start_date': '2023-12-15',
        'end_date': '2023-12-31',
        'description': '€5 korting op alle desserts',
        'conditions': 'Geldig tijdens de feestdagen',
        'usage_count': 178,
        'usage_limit': 300,
        'revenue_impact': 890.00,
        'created_date': '2023-11-20',
        'restaurants': ['1', '2', '3'],
        'menu_items': ['desserts'],
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultCampaigns() {
    return [
      {
        'id': '1',
        'name': 'Social Media Boost',
        'type': 'social_media',
        'status': 'active',
        'budget': 500.00,
        'spent': 234.50,
        'impressions': 12450,
        'clicks': 567,
        'conversions': 89,
        'ctr': 4.6,
        'conversion_rate': 15.7,
        'roi': 245,
        'start_date': '2024-01-01',
        'end_date': '2024-01-31',
        'platforms': ['facebook', 'instagram'],
        'target_audience': 'Lokale foodies, 25-45 jaar',
      },
      {
        'id': '2',
        'name': 'Google Ads - Lunch',
        'type': 'search_ads',
        'status': 'active',
        'budget': 300.00,
        'spent': 156.78,
        'impressions': 8900,
        'clicks': 234,
        'conversions': 45,
        'ctr': 2.6,
        'conversion_rate': 19.2,
        'roi': 189,
        'start_date': '2024-01-01',
        'end_date': '2024-01-31',
        'keywords': ['lunch restaurant', 'business lunch', 'gezonde lunch'],
        'target_audience': 'Zakelijke klanten',
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultTemplates() {
    return [
      {
        'id': '1',
        'name': 'Happy Hour Template',
        'type': 'happy_hour',
        'description': 'Standaard happy hour promotie template',
        'discount_type': 'percentage',
        'discount_value': 25,
        'time_restrictions': '17:00-19:00',
        'day_restrictions': [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday'
        ],
        'usage_count': 12,
      },
      {
        'id': '2',
        'name': 'Nieuwe Klant Welkom',
        'type': 'new_customer',
        'description': 'Welkomstkorting voor nieuwe klanten',
        'discount_type': 'fixed',
        'discount_value': 10,
        'min_order_value': 25,
        'usage_count': 8,
      },
      {
        'id': '3',
        'name': 'Weekend Special',
        'type': 'seasonal',
        'description': 'Weekend korting template',
        'discount_type': 'percentage',
        'discount_value': 15,
        'day_restrictions': ['saturday', 'sunday'],
        'usage_count': 5,
      },
    ];
  }

  void _filterPromotions() {
    List<Map<String, dynamic>> filtered = List.from(_promotions);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((promotion) {
        return promotion['name']
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            promotion['description']
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
      }).toList();
    }

    // Status filter
    if (_selectedStatus != 'all') {
      filtered = filtered
          .where((promotion) => promotion['status'] == _selectedStatus)
          .toList();
    }

    // Type filter
    if (_selectedType != 'all') {
      filtered = filtered
          .where((promotion) => promotion['type'] == _selectedType)
          .toList();
    }

    // Sort
    filtered.sort((a, b) {
      dynamic aValue = a[_sortBy];
      dynamic bValue = b[_sortBy];

      if (aValue is String && bValue is String) {
        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      } else if (aValue is num && bValue is num) {
        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      }

      return 0;
    });

    setState(() {
      _filteredPromotions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Promoties & Marketing'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPromotionsData,
            tooltip: 'Vernieuwen',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'analytics':
                  _showAnalytics();
                  break;
                case 'export':
                  _exportPromotions();
                  break;
                case 'settings':
                  _showPromotionSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Analytics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Exporteren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Instellingen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              // Search Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Zoek promoties...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterPromotions();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
              ),

              // Filters
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.surface,
                        items: _statusOptions.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                          _filterPromotions();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.surface,
                        items: _typeOptions.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                          _filterPromotions();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.onPrimary,
                labelColor: AppColors.onPrimary,
                unselectedLabelColor:
                    AppColors.withAlphaFraction(AppColors.onPrimary, 0.7),
                isScrollable: true,
                tabs: const [
                  Tab(
                      text: 'Promoties',
                      icon: Icon(Icons.local_offer, size: 16)),
                  Tab(text: 'Campagnes', icon: Icon(Icons.campaign, size: 16)),
                  Tab(
                      text: 'Templates',
                      icon: Icon(Icons.template_outlined, size: 16)),
                  Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPromotionsTab(),
                _buildCampaignsTab(),
                _buildTemplatesTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePromotionDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPromotionsTab() {
    if (_filteredPromotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Geen promoties gevonden',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maak je eerste promotie aan',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreatePromotionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Promotie Aanmaken'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Sort Options
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Sorteer op:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _sortBy,
                underline: Container(),
                items: _sortOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  _filterPromotions();
                },
              ),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _sortAscending = !_sortAscending);
                  _filterPromotions();
                },
              ),
              const Spacer(),
              Text(
                '${_filteredPromotions.length} promoties',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Promotions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredPromotions.length,
            itemBuilder: (context, index) {
              final promotion = _filteredPromotions[index];
              return _buildPromotionCard(promotion);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    Color statusColor;
    IconData statusIcon;

    switch (promotion['status']) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.play_circle;
        break;
      case 'scheduled':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'paused':
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle;
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        break;
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'draft':
        statusColor = Colors.amber;
        statusIcon = Icons.edit;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    String discountText = promotion['discount_type'] == 'percentage'
        ? '${promotion['discount_value']}%'
        : '€${promotion['discount_value']}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _typeOptions[promotion['type']] ?? promotion['type'],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    discountText,
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.withAlphaFraction(statusColor, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _statusOptions[promotion['status']] ?? 'Onbekend',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editPromotion(promotion);
                        break;
                      case 'duplicate':
                        _duplicatePromotion(promotion);
                        break;
                      case 'pause':
                        _pausePromotion(promotion);
                        break;
                      case 'activate':
                        _activatePromotion(promotion);
                        break;
                      case 'delete':
                        _deletePromotion(promotion);
                        break;
                    }
                  },
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
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Dupliceren'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (promotion['status'] == 'active')
                      const PopupMenuItem(
                        value: 'pause',
                        child: ListTile(
                          leading: Icon(Icons.pause),
                          title: Text('Pauzeren'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (promotion['status'] == 'paused' ||
                        promotion['status'] == 'draft')
                      const PopupMenuItem(
                        value: 'activate',
                        child: ListTile(
                          leading: Icon(Icons.play_arrow),
                          title: Text('Activeren'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Verwijderen',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              promotion['description'],
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            if (promotion['conditions'] != null) ...[
              const SizedBox(height: 8),
              Text(
                promotion['conditions'],
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gebruikt',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        promotion['usage_limit'] != null
                            ? '${promotion['usage_count']}/${promotion['usage_limit']}'
                            : '${promotion['usage_count']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Omzet Impact',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '€${promotion['revenue_impact'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Periode',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${promotion['start_date']} - ${promotion['end_date']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (promotion['usage_limit'] != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: promotion['usage_count'] / promotion['usage_limit'],
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _campaigns.length,
      itemBuilder: (context, index) {
        final campaign = _campaigns[index];
        return _buildCampaignCard(campaign);
      },
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final budgetUsed =
        (campaign['spent'] / campaign['budget'] * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        campaign['type'].replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.AppColors.withAlphaFraction(green, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Actief',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Budget Progress
            Row(
              children: [
                Text(
                  'Budget: €${campaign['spent'].toStringAsFixed(2)} / €${campaign['budget'].toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  '$budgetUsed%',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: campaign['spent'] / campaign['budget'],
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            const SizedBox(height: 16),

            // Performance Metrics
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildMetricCard('Impressies', '${campaign['impressions']}',
                    Icons.visibility),
                _buildMetricCard(
                    'Clicks', '${campaign['clicks']}', Icons.mouse),
                _buildMetricCard('Conversies', '${campaign['conversions']}',
                    Icons.trending_up),
                _buildMetricCard('CTR', '${campaign['ctr']}%', Icons.ads_click),
                _buildMetricCard('Conv. Rate',
                    '${campaign['conversion_rate']}%', Icons.percent),
                _buildMetricCard(
                    'ROI', '${campaign['roi']}%', Icons.attach_money),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${campaign['start_date']} - ${campaign['end_date']}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _viewCampaignDetails(campaign),
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    String discountText = template['discount_type'] == 'percentage'
        ? '${template['discount_value']}%'
        : '€${template['discount_value']}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            discountText,
            style: TextStyle(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          template['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template['description']),
            const SizedBox(height: 4),
            Text(
              'Gebruikt: ${template['usage_count']} keer',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _useTemplate(template),
          child: const Text('Gebruiken'),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promotie Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildAnalyticsCard(
                  'Actieve Promoties', '3', Icons.local_offer, Colors.green),
              _buildAnalyticsCard(
                  'Totaal Gebruikt', '679', Icons.redeem, Colors.blue),
              _buildAnalyticsCard(
                  'Omzet Impact', '€9,800', Icons.euro, Colors.purple),
              _buildAnalyticsCard(
                  'Gem. ROI', '215%', Icons.trending_up, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Presterende Promoties',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._promotions.take(3).map((promotion) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              promotion['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${promotion['usage_count']} gebruikt',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '€${promotion['revenue_impact'].toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePromotionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuwe Promotie'),
        content: const Text(
            'Promotie aanmaken functionaliteit wordt binnenkort toegevoegd.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editPromotion(Map<String, dynamic> promotion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${promotion['name']} bewerken wordt binnenkort toegevoegd')),
    );
  }

  void _duplicatePromotion(Map<String, dynamic> promotion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${promotion['name']} dupliceren wordt binnenkort toegevoegd')),
    );
  }

  void _pausePromotion(Map<String, dynamic> promotion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${promotion['name']} gepauzeerd')),
    );
  }

  void _activatePromotion(Map<String, dynamic> promotion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${promotion['name']} geactiveerd')),
    );
  }

  void _deletePromotion(Map<String, dynamic> promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promotie Verwijderen'),
        content:
            Text('Weet je zeker dat je ${promotion['name']} wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${promotion['name']} verwijderd')),
              );
            },
            child:
                const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewCampaignDetails(Map<String, dynamic> campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('${campaign['name']} details wordt binnenkort toegevoegd')),
    );
  }

  void _useTemplate(Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Template ${template['name']} gebruiken wordt binnenkort toegevoegd')),
    );
  }

  void _showAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Uitgebreide analytics wordt binnenkort toegevoegd')),
    );
  }

  void _exportPromotions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Promoties exporteren wordt binnenkort toegevoegd')),
    );
  }

  void _showPromotionSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Promotie instellingen wordt binnenkort toegevoegd')),
    );
  }
}
