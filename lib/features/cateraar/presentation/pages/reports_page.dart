import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CateraarReportsPage extends ConsumerStatefulWidget {
  const CateraarReportsPage({super.key});

  @override
  ConsumerState<CateraarReportsPage> createState() => _CateraarReportsPageState();
}

class _CateraarReportsPageState extends ConsumerState<CateraarReportsPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  late TabController _tabController;
  
  bool _isLoading = true;
  bool _isExporting = false;
  Map<String, dynamic> _reportsData = {};
  String _selectedPeriod = 'last_30_days';
  String _selectedRestaurant = 'all';
  List<Map<String, dynamic>> _restaurants = [];

  final Map<String, String> _periodOptions = {
    'today': 'Vandaag',
    'yesterday': 'Gisteren',
    'last_7_days': 'Laatste 7 dagen',
    'last_30_days': 'Laatste 30 dagen',
    'last_90_days': 'Laatste 90 dagen',
    'this_month': 'Deze maand',
    'last_month': 'Vorige maand',
    'this_year': 'Dit jaar',
    'custom': 'Aangepast',
  };

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'id': 'overview',
      'name': 'Overzicht',
      'icon': Icons.dashboard,
      'description': 'Algemene prestatie statistieken',
    },
    {
      'id': 'revenue',
      'name': 'Omzet',
      'icon': Icons.euro,
      'description': 'Omzet en financiële rapporten',
    },
    {
      'id': 'customers',
      'name': 'Klanten',
      'icon': Icons.people,
      'description': 'Klant gedrag en statistieken',
    },
    {
      'id': 'menu_performance',
      'name': 'Menu Prestaties',
      'icon': Icons.restaurant_menu,
      'description': 'Populaire items en trends',
    },
    {
      'id': 'marketing',
      'name': 'Marketing',
      'icon': Icons.campaign,
      'description': 'Marketing campagne resultaten',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getReportsData(
        period: _selectedPeriod,
        restaurantId: _selectedRestaurant,
      );
      
      setState(() {
        _reportsData = response['reports'] ?? {};
        _restaurants = List<Map<String, dynamic>>.from(response['restaurants'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _reportsData = _getDefaultReportsData();
        _restaurants = _getDefaultRestaurants();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getDefaultReportsData() {
    return {
      'overview': {
        'total_revenue': 15420.50,
        'total_orders': 342,
        'total_customers': 287,
        'avg_order_value': 45.12,
        'qr_scans': 1234,
        'menu_views': 2567,
        'favorites': 189,
        'reviews': 45,
        'avg_rating': 4.3,
        'growth_revenue': 12.5,
        'growth_orders': 8.3,
        'growth_customers': 15.2,
      },
      'revenue': {
        'daily_revenue': [120, 150, 180, 200, 175, 220, 190],
        'revenue_by_category': {
          'Hoofdgerechten': 8500,
          'Voorgerechten': 3200,
          'Desserts': 2100,
          'Dranken': 1620,
        },
        'payment_methods': {
          'Creditcard': 65,
          'Contant': 20,
          'Pin': 15,
        },
      },
      'customers': {
        'new_customers': 45,
        'returning_customers': 242,
        'customer_retention': 84.3,
        'avg_visits_per_customer': 2.8,
        'peak_hours': {
          '12:00': 45,
          '13:00': 67,
          '18:00': 89,
          '19:00': 92,
          '20:00': 78,
        },
        'demographics': {
          '18-25': 15,
          '26-35': 35,
          '36-45': 28,
          '46-55': 15,
          '55+': 7,
        },
      },
      'menu_performance': {
        'top_items': [
          {'name': 'Pasta Carbonara', 'orders': 89, 'revenue': 1245.60},
          {'name': 'Caesar Salade', 'orders': 67, 'revenue': 804.00},
          {'name': 'Ribeye Steak', 'orders': 45, 'revenue': 1350.00},
          {'name': 'Tiramisu', 'orders': 56, 'revenue': 392.00},
          {'name': 'Huiswijn Rood', 'orders': 78, 'revenue': 468.00},
        ],
        'category_performance': {
          'Hoofdgerechten': {'orders': 234, 'revenue': 8500, 'margin': 65},
          'Voorgerechten': {'orders': 156, 'revenue': 3200, 'margin': 72},
          'Desserts': {'orders': 89, 'revenue': 2100, 'margin': 78},
          'Dranken': {'orders': 198, 'revenue': 1620, 'margin': 85},
        },
      },
      'marketing': {
        'qr_scan_sources': {
          'Tafel QR': 856,
          'Social Media': 234,
          'Website': 144,
        },
        'referral_sources': {
          'Direct': 45,
          'Google': 32,
          'Facebook': 18,
          'Instagram': 12,
        },
        'campaign_performance': [
          {'name': 'Zomer Actie', 'clicks': 1234, 'conversions': 89, 'roi': 245},
          {'name': 'Happy Hour', 'clicks': 876, 'conversions': 67, 'roi': 189},
        ],
      },
    };
  }

  List<Map<String, dynamic>> _getDefaultRestaurants() {
    return [
      {'id': 'all', 'name': 'Alle Restaurants'},
      {'id': '1', 'name': 'Restaurant De Smaak'},
      {'id': '2', 'name': 'Café Central'},
      {'id': '3', 'name': 'Bistro Milano'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rapporten'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportsData,
            tooltip: 'Vernieuwen',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export_pdf':
                  _exportReport('pdf');
                  break;
                case 'export_excel':
                  _exportReport('excel');
                  break;
                case 'export_csv':
                  _exportReport('csv');
                  break;
                case 'schedule_report':
                  _scheduleReport();
                  break;
                case 'share_report':
                  _shareReport();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Exporteer als PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_excel',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Exporteer als Excel'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Exporteer als CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'schedule_report',
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Rapport Inplannen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share_report',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Rapport Delen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPeriod,
                        decoration: const InputDecoration(
                          labelText: 'Periode',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.surface,
                        items: _periodOptions.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPeriod = value!);
                          _loadReportsData();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRestaurant,
                        decoration: const InputDecoration(
                          labelText: 'Restaurant',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.surface,
                        items: _restaurants.map((restaurant) {
                          return DropdownMenuItem<String>(
                            value: restaurant['id'],
                            child: Text(restaurant['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedRestaurant = value!);
                          _loadReportsData();
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
                unselectedLabelColor: AppColors.onPrimary.withOpacity(0.7),
                isScrollable: true,
                tabs: _reportTypes.map((type) => Tab(
                  text: type['name'],
                  icon: Icon(type['icon'], size: 16),
                )).toList(),
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
                _buildOverviewTab(),
                _buildRevenueTab(),
                _buildCustomersTab(),
                _buildMenuPerformanceTab(),
                _buildMarketingTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final overview = _reportsData['overview'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics
          Text(
            'Belangrijkste Statistieken',
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
              _buildMetricCard(
                'Totale Omzet',
                '€${overview['total_revenue']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.euro,
                Colors.green,
                '${overview['growth_revenue']?.toStringAsFixed(1) ?? '0.0'}%',
              ),
              _buildMetricCard(
                'Bestellingen',
                '${overview['total_orders'] ?? 0}',
                Icons.shopping_cart,
                Colors.blue,
                '${overview['growth_orders']?.toStringAsFixed(1) ?? '0.0'}%',
              ),
              _buildMetricCard(
                'Klanten',
                '${overview['total_customers'] ?? 0}',
                Icons.people,
                Colors.purple,
                '${overview['growth_customers']?.toStringAsFixed(1) ?? '0.0'}%',
              ),
              _buildMetricCard(
                'Gem. Bestelling',
                '€${overview['avg_order_value']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.receipt,
                Colors.orange,
                null,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Engagement Metrics
          Text(
            'Betrokkenheid',
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
              _buildMetricCard(
                'QR Scans',
                '${overview['qr_scans'] ?? 0}',
                Icons.qr_code,
                Colors.teal,
                null,
              ),
              _buildMetricCard(
                'Menu Bekeken',
                '${overview['menu_views'] ?? 0}',
                Icons.visibility,
                Colors.indigo,
                null,
              ),
              _buildMetricCard(
                'Favorieten',
                '${overview['favorites'] ?? 0}',
                Icons.favorite,
                Colors.red,
                null,
              ),
              _buildMetricCard(
                'Reviews',
                '${overview['reviews'] ?? 0}',
                Icons.star,
                Colors.amber,
                '${overview['avg_rating']?.toStringAsFixed(1) ?? '0.0'} ⭐',
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Snelle Acties',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportReport('pdf'),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF Export'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportReport('excel'),
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Excel Export'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _scheduleReport,
                          icon: const Icon(Icons.schedule),
                          label: const Text('Rapport Inplannen'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shareReport,
                          icon: const Icon(Icons.share),
                          label: const Text('Delen'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    final revenue = _reportsData['revenue'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Chart Placeholder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Omzet Trend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Omzet Grafiek',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Interactieve grafiek wordt hier getoond',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Revenue by Category
          Text(
            'Omzet per Categorie',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (revenue['revenue_by_category'] as Map<String, dynamic>?)?.entries.map((entry) {
                  final total = (revenue['revenue_by_category'] as Map<String, dynamic>).values.fold(0.0, (sum, value) => sum + value);
                  final percentage = (entry.value / total * 100).toStringAsFixed(1);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: entry.value / total,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '€${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($percentage%)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList() ?? [],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Methods
          Text(
            'Betaalmethoden',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: (revenue['payment_methods'] as Map<String, dynamic>?)?.entries.map((entry) {
              IconData icon;
              Color color;
              
              switch (entry.key) {
                case 'Creditcard':
                  icon = Icons.credit_card;
                  color = Colors.blue;
                  break;
                case 'Contant':
                  icon = Icons.money;
                  color = Colors.green;
                  break;
                case 'Pin':
                  icon = Icons.payment;
                  color = Colors.orange;
                  break;
                default:
                  icon = Icons.payment;
                  color = Colors.grey;
              }
              
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${entry.value}%',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList() ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    final customers = _reportsData['customers'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Overview
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMetricCard(
                'Nieuwe Klanten',
                '${customers['new_customers'] ?? 0}',
                Icons.person_add,
                Colors.green,
                null,
              ),
              _buildMetricCard(
                'Terugkerende Klanten',
                '${customers['returning_customers'] ?? 0}',
                Icons.repeat,
                Colors.blue,
                null,
              ),
              _buildMetricCard(
                'Klant Retentie',
                '${customers['customer_retention']?.toStringAsFixed(1) ?? '0.0'}%',
                Icons.trending_up,
                Colors.purple,
                null,
              ),
              _buildMetricCard(
                'Gem. Bezoeken',
                '${customers['avg_visits_per_customer']?.toStringAsFixed(1) ?? '0.0'}',
                Icons.visit_history,
                Colors.orange,
                null,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Peak Hours
          Text(
            'Piekuren',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (customers['peak_hours'] as Map<String, dynamic>?)?.entries.map((entry) {
                  final maxValue = (customers['peak_hours'] as Map<String, dynamic>).values.fold(0, (max, value) => value > max ? value : max);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: entry.value / maxValue,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList() ?? [],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Demographics
          Text(
            'Leeftijdsgroepen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (customers['demographics'] as Map<String, dynamic>?)?.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: entry.value / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${entry.value}%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList() ?? [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuPerformanceTab() {
    final menuPerformance = _reportsData['menu_performance'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Items
          Text(
            'Top Menu Items',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Column(
              children: (menuPerformance['top_items'] as List<dynamic>?)?.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${item['orders']} bestellingen'),
                  trailing: Text(
                    '€${item['revenue'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList() ?? [],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Category Performance
          Text(
            'Categorie Prestaties',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 1,
            childAspectRatio: 4,
            mainAxisSpacing: 12,
            children: (menuPerformance['category_performance'] as Map<String, dynamic>?)?.entries.map((entry) {
              final category = entry.key;
              final data = entry.value;
              
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${data['orders']} bestellingen',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '€${data['revenue']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Omzet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${data['margin']}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: data['margin'] > 70 ? Colors.green : 
                                       data['margin'] > 50 ? Colors.orange : Colors.red,
                              ),
                            ),
                            Text(
                              'Marge',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList() ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingTab() {
    final marketing = _reportsData['marketing'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Scan Sources
          Text(
            'QR Scan Bronnen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: (marketing['qr_scan_sources'] as Map<String, dynamic>?)?.entries.map((entry) {
              IconData icon;
              Color color;
              
              switch (entry.key) {
                case 'Tafel QR':
                  icon = Icons.table_restaurant;
                  color = Colors.blue;
                  break;
                case 'Social Media':
                  icon = Icons.share;
                  color = Colors.purple;
                  break;
                case 'Website':
                  icon = Icons.web;
                  color = Colors.green;
                  break;
                default:
                  icon = Icons.qr_code;
                  color = Colors.grey;
              }
              
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList() ?? [],
          ),
          
          const SizedBox(height: 24),
          
          // Referral Sources
          Text(
            'Verwijzingsbronnen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (marketing['referral_sources'] as Map<String, dynamic>?)?.entries.map((entry) {
                  final total = (marketing['referral_sources'] as Map<String, dynamic>).values.fold(0, (sum, value) => sum + value);
                  final percentage = (entry.value / total * 100).toStringAsFixed(1);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: entry.value / total,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($percentage%)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList() ?? [],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Campaign Performance
          Text(
            'Campagne Prestaties',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Column(
            children: (marketing['campaign_performance'] as List<dynamic>?)?.map((campaign) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${campaign['clicks']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Clicks',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${campaign['conversions']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Conversies',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${campaign['roi']}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: campaign['roi'] > 200 ? Colors.green : 
                                           campaign['roi'] > 100 ? Colors.orange : Colors.red,
                                  ),
                                ),
                                Text(
                                  'ROI',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
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
            }).toList() ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String? growth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                if (growth != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: growth.startsWith('-') ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      growth,
                      style: TextStyle(
                        color: growth.startsWith('-') ? Colors.red : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
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

  Future<void> _exportReport(String format) async {
    setState(() => _isExporting = true);
    
    try {
      await _apiService.exportReport(
        format: format,
        period: _selectedPeriod,
        restaurantId: _selectedRestaurant,
        reportType: _reportTypes[_tabController.index]['id'],
      );
      
      setState(() => _isExporting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapport geëxporteerd als ${format.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij exporteren: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scheduleReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rapport Inplannen'),
        content: const Text('Automatische rapporten worden binnenkort toegevoegd.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapport delen wordt binnenkort toegevoegd')),
    );
  }
}

