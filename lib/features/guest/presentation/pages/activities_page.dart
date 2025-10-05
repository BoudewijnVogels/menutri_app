import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ActivitiesPage extends ConsumerStatefulWidget {
  const ActivitiesPage({super.key});

  @override
  ConsumerState<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends ConsumerState<ActivitiesPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = false;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _eatenHistory = [];

  String _selectedFilter = 'all';
  final List<String> _filterOptions = [
    'all',
    'scan',
    'favorite',
    'eaten',
    'review'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final futures = await Future.wait([
        _apiService.getUserActivity(),
        _apiService.getFavorites(),
        _apiService.getEatenHistory(),
      ]);

      setState(() {
        _activities = List<Map<String, dynamic>>.from(
            (futures[0] as Map<String, dynamic>)['activities'] ?? []);
        _favorites = List<Map<String, dynamic>>.from(
            (futures[1] as Map<String, dynamic>)['favorites'] ?? []);
        _eatenHistory = List<Map<String, dynamic>>.from(
            (futures[2] as Map<String, dynamic>)['eaten_items'] ?? []);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden activiteiten: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activiteiten'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.onPrimary,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor:
              AppColors.withAlphaFraction(AppColors.onPrimary, 0.7),
          tabs: const [
            Tab(text: 'Alle Activiteiten'),
            Tab(text: 'Favorieten'),
            Tab(text: 'Gegeten'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getFilterLabel(filter)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivitiesTab(),
                      _buildFavoritesTab(),
                      _buildEatenTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    final filteredActivities = _selectedFilter == 'all'
        ? _activities
        : _activities
            .where((activity) => activity['activity_type'] == _selectedFilter)
            .toList();

    if (filteredActivities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'Geen activiteiten',
        subtitle: 'Je activiteiten verschijnen hier zodra je de app gebruikt.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredActivities.length,
        itemBuilder: (context, index) {
          final activity = filteredActivities[index];
          return _buildActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Geen favorieten',
        subtitle: 'Voeg restaurants en gerechten toe aan je favorieten.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          return _buildFavoriteCard(favorite);
        },
      ),
    );
  }

  Widget _buildEatenTab() {
    if (_eatenHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant,
        title: 'Geen gegeten items',
        subtitle: 'Items die je als gegeten markeert verschijnen hier.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _eatenHistory.length,
        itemBuilder: (context, index) {
          final eaten = _eatenHistory[index];
          return _buildEatenCard(eaten);
        },
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final activityType = activity['activity_type'] ?? '';
    final createdAt =
        DateTime.tryParse(activity['created_at'] ?? '') ?? DateTime.now();

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    switch (activityType) {
      case 'scan':
        icon = Icons.qr_code_scanner;
        iconColor = AppColors.primary;
        title = 'QR Code gescand';
        subtitle = activity['restaurant_name'] ?? 'Restaurant menu';
        break;
      case 'favorite':
        icon = Icons.favorite;
        iconColor = Colors.red;
        title = 'Toegevoegd aan favorieten';
        subtitle = activity['item_name'] ?? 'Item';
        break;
      case 'eaten':
        icon = Icons.restaurant;
        iconColor = Colors.green;
        title = 'Gemarkeerd als gegeten';
        subtitle = activity['item_name'] ?? 'Item';
        break;
      case 'review':
        icon = Icons.star;
        iconColor = Colors.amber;
        title = 'Review geschreven';
        subtitle = activity['restaurant_name'] ?? 'Restaurant';
        break;
      default:
        icon = Icons.circle;
        iconColor = AppColors.textSecondary;
        title = 'Activiteit';
        subtitle = 'Onbekende activiteit';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.withAlphaFraction(iconColor, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(createdAt),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showActivityOptions(activity),
        ),
        onTap: () => _navigateToActivityDetail(activity),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite) {
    final createdAt =
        DateTime.tryParse(favorite['created_at'] ?? '') ?? DateTime.now();
    final targetType = favorite['target_type'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.withAlphaFraction(Colors.red, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            targetType == 'restaurant' ? Icons.store : Icons.restaurant,
            color: Colors.red,
          ),
        ),
        title: Text(
          favorite['target_name'] ?? 'Favoriet',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(targetType == 'restaurant' ? 'Restaurant' : 'Menu item'),
            const SizedBox(height: 4),
            Text(
              'Toegevoegd op ${DateFormat('dd MMM yyyy').format(createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () => _removeFavorite(favorite['id']),
        ),
        onTap: () => _navigateToFavoriteDetail(favorite),
      ),
    );
  }

  Widget _buildEatenCard(Map<String, dynamic> eaten) {
    final eatenAt =
        DateTime.tryParse(eaten['eaten_at'] ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.withAlphaFraction(Colors.green, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.restaurant, color: Colors.green),
        ),
        title: Text(
          eaten['item_name'] ?? 'Gegeten item',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eaten['restaurant_name'] != null)
              Text(eaten['restaurant_name']),
            const SizedBox(height: 4),
            Text(
              'Gegeten op ${DateFormat('dd MMM yyyy, HH:mm').format(eatenAt)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: eaten['myfitnesspal_logged'] == true
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MFP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () => _navigateToEatenDetail(eaten),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'Alle';
      case 'scan':
        return 'Scans';
      case 'favorite':
        return 'Favorieten';
      case 'eaten':
        return 'Gegeten';
      case 'review':
        return 'Reviews';
      default:
        return filter;
    }
  }

  void _showActivityOptions(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Delen'),
              onTap: () {
                Navigator.pop(context);
                _shareActivity(activity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Verwijderen'),
              onTap: () {
                Navigator.pop(context);
                _deleteActivity(activity['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFavorite(int favoriteId) async {
    try {
      await _apiService.deleteFavorite(favoriteId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favoriet verwijderd')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij verwijderen: $e')),
        );
      }
    }
  }

  void _shareActivity(Map<String, dynamic> activity) {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delen functionaliteit komt binnenkort')),
    );
  }

  Future<void> _deleteActivity(int activityId) async {
    // Implement activity deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activiteit verwijderd')),
    );
  }

  void _navigateToActivityDetail(Map<String, dynamic> activity) {
    // Navigate to relevant detail page based on activity type
  }

  void _navigateToFavoriteDetail(Map<String, dynamic> favorite) {
    // Navigate to restaurant or menu item detail
  }

  void _navigateToEatenDetail(Map<String, dynamic> eaten) {
    // Navigate to nutrition log or item detail
  }
}
