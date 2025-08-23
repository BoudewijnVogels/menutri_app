import 'dart:math' as math; // ✅ voor min()
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;

  bool _isLoading = true;

  // Kan Map of List zijn, afhankelijk van de backend-respons
  Map<String, dynamic>? _analyticsMap;
  List<dynamic> _analyticsList = [];

  List<Map<String, dynamic>> _restaurants = [];
  Map<String, dynamic>? _selectedRestaurant;
  String _selectedPeriod = '7d';

  final Map<String, String> _periodOptions = {
    '1d': 'Vandaag',
    '7d': '7 Dagen',
    '30d': '30 Dagen',
    '90d': '3 Maanden',
    '1y': '1 Jaar',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final restaurantsResponse = await _apiService.getRestaurants();
      final restaurants = List<Map<String, dynamic>>.from(
        restaurantsResponse['restaurants'] ?? [],
      );

      setState(() {
        _restaurants = restaurants;
        if (restaurants.isNotEmpty) {
          _selectedRestaurant = restaurants.first;
        } else {
          _selectedRestaurant = null;
        }
      });

      await _loadAnalytics();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden data: $e')),
        );
      }
    }
  }

  Future<void> _loadAnalytics() async {
    // Als je alle restaurants wilt tonen, laat restaurantId null
    final restaurantId = _selectedRestaurant?['id'];

    try {
      // ✅ maak response expliciet dynamic om List/Map flexibel af te vangen
      final dynamic response = await _apiService.getAnalytics(
        restaurantId: restaurantId,
        period: _selectedPeriod,
        metric:
            'overview', // pas aan indien jouw backend andere metric verwacht
      );

      setState(() {
        if (response is Map<String, dynamic>) {
          _analyticsMap = response;
          _analyticsList = [];
        } else if (response is List) {
          _analyticsList = response;
          _analyticsMap = null;
        } else {
          // Onbekende vorm -> leeg maken zodat UI niet crasht
          _analyticsMap = null;
          _analyticsList = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden analytics: $e')),
        );
      }
    }
  }

  // Haal een "overview"-map op, ongeacht of de bron een Map of List is
  Map<String, dynamic> _getOverview() {
    // Backend geeft een object terug met een 'overview' veld
    if (_analyticsMap != null) {
      final obj = _analyticsMap!;
      final over = obj['overview'];
      if (over is Map<String, dynamic>) return over;
      return {};
    }

    // Backend geeft een lijst terug – simpele fallback: neem eerste item als Map
    if (_analyticsList.isNotEmpty && _analyticsList.first is Map) {
      return Map<String, dynamic>.from(_analyticsList.first as Map);
    }

    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(),
          ),
        ],
        bottom: _restaurants.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.onPrimary,
                  labelColor: AppColors.onPrimary,
                  unselectedLabelColor:
                      AppColors.withAlphaFraction(AppColors.onPrimary, 0.7),
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Overzicht'),
                    Tab(text: 'QR Scans'),
                    Tab(text: 'Menu Items'),
                    Tab(text: 'Reviews'),
                  ],
                ),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _restaurants.isEmpty
              ? _buildNoRestaurantsState()
              : Column(
                  children: [
                    // Filters
                    _buildControls(),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildQRScansTab(),
                          _buildMenuItemsTab(),
                          _buildReviewsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNoRestaurantsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Geen Analytics Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg eerst een restaurant toe om analytics te bekijken',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/cateraar/restaurants/add'),
              icon: const Icon(Icons.add),
              label: const Text('Restaurant Toevoegen'),
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

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.withAlphaFraction(Colors.black, 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Restaurant selector (nullable!)
          Row(
            children: [
              Icon(Icons.restaurant, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<Map<String, dynamic>?>(
                  value: _selectedRestaurant,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<Map<String, dynamic>?>(
                      value: null,
                      child: Text('Alle Restaurants'),
                    ),
                    ..._restaurants.map((restaurant) {
                      return DropdownMenuItem<Map<String, dynamic>?>(
                        value: restaurant,
                        child: Text(restaurant['name'] ?? ''),
                      );
                    }).toList(),
                  ],
                  onChanged: (restaurant) {
                    setState(() {
                      _selectedRestaurant = restaurant;
                    });
                    _loadAnalytics();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Period selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periodOptions.entries.map((entry) {
                final isSelected = _selectedPeriod == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPeriod = entry.key;
                      });
                      _loadAnalytics();
                    },
                    backgroundColor: AppColors.background,
                    selectedColor:
                        AppColors.withAlphaFraction(AppColors.primary, 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final overview = _getOverview();

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key metrics
            _buildKeyMetrics(overview),

            const SizedBox(height: 24),

            // Performance chart
            _buildPerformanceChart(overview),

            const SizedBox(height: 24),

            // Top performing items
            _buildTopPerformingItems(overview),

            const SizedBox(height: 24),

            // Recent activity
            _buildRecentActivity(overview),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
  }) {
    final isPositive = !change.startsWith('-');

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.withAlphaFraction(
                      isPositive ? Colors.green : Colors.red, 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(Map<String, dynamic> overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(
              title: 'QR Scans',
              value: '${overview['qr_scans'] ?? 0}',
              change: '${overview['qr_scans_change'] ?? 0}%',
              icon: Icons.qr_code_scanner,
              color: Colors.blue,
            ),
            _buildMetricCard(
              title: 'Menu Views',
              value: '${overview['menu_views'] ?? 0}',
              change: '${overview['menu_views_change'] ?? 0}%',
              icon: Icons.visibility,
              color: Colors.green,
            ),
            _buildMetricCard(
              title: 'Favorieten',
              value: '${overview['favorites'] ?? 0}',
              change: '${overview['favorites_change'] ?? 0}%',
              icon: Icons.favorite,
              color: Colors.red,
            ),
            _buildMetricCard(
              title: 'Reviews',
              value: '${overview['reviews'] ?? 0}',
              change: '${overview['reviews_change'] ?? 0}%',
              icon: Icons.star,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceChart(Map<String, dynamic> overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prestatie Trend',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
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
                const SizedBox(height: 16),
                Text(
                  'Interactieve Grafiek',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gedetailleerde grafieken worden binnenkort toegevoegd',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformingItems(Map<String, dynamic> overview) {
    final topItems =
        List<Map<String, dynamic>>.from(overview['top_items'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Best Presterende Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: topItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Geen data beschikbaar',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topItems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = topItems[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.withAlphaFraction(AppColors.primary, 0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(item['name'] ?? ''),
                      subtitle: Text('${item['views'] ?? 0} views'),
                      trailing: Text(
                        '${item['favorites'] ?? 0} ♥',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic> overview) {
    final activities =
        List<Map<String, dynamic>>.from(overview['recent_activities'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recente Activiteit',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: activities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Geen recente activiteit',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // ✅ clamp → int: gebruik min()
                  itemCount: math.min(activities.length, 5),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ListTile(
                      leading: _getActivityIcon(activity['type'] as String?),
                      title: Text((activity['description'] ?? '') as String),
                      subtitle: Text(
                          _formatDateTime(activity['created_at'] as String?)),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQRScansTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'QR Scan Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gedetailleerde QR scan analytics worden binnenkort toegevoegd',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Menu Item Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gedetailleerde menu item analytics worden binnenkort toegevoegd',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Review Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gedetailleerde review analytics worden binnenkort toegevoegd',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics Exporteren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecteer het formaat voor export:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV Export'),
              subtitle: const Text(
                  'Geschikt voor Excel en andere spreadsheet programma\'s'),
              onTap: () {
                Navigator.pop(context);
                _exportCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Rapport'),
              subtitle: const Text('Volledig rapport met grafieken'),
              onTap: () {
                Navigator.pop(context);
                _exportPDF();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV() async {
    try {
      await _apiService.exportAnalyticsCSV(
        restaurantId: _selectedRestaurant?['id'],
        period: _selectedPeriod,
        metric: 'overview',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'CSV export gestart - je ontvangt een email met de download link'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij CSV export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportPDF() async {
    try {
      await _apiService.exportAnalyticsPDF(
        restaurantId: _selectedRestaurant?['id'],
        period: _selectedPeriod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'PDF rapport wordt gegenereerd - je ontvangt een email met de download link'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij PDF export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _getActivityIcon(String? type) {
    switch (type) {
      case 'qr_scan':
        return Icon(Icons.qr_code_scanner, color: AppColors.primary);
      case 'menu_view':
        return Icon(Icons.visibility, color: Colors.blue);
      case 'favorite':
        return Icon(Icons.favorite, color: Colors.red);
      case 'review':
        return Icon(Icons.star, color: Colors.orange);
      default:
        return Icon(Icons.info, color: AppColors.textSecondary);
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';

    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} dagen geleden';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} uur geleden';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minuten geleden';
      } else {
        return 'Zojuist';
      }
    } catch (e) {
      return dateTime;
    }
  }
}
