import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class RestaurantsPage extends ConsumerStatefulWidget {
  const RestaurantsPage({super.key});

  @override
  ConsumerState<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends ConsumerState<RestaurantsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _filteredRestaurants = [];
  String _selectedFilter = 'all';

  final Map<String, String> _filterOptions = {
    'all': 'Alle',
    'active': 'Actief',
    'inactive': 'Inactief',
    'draft': 'Concept',
  };

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _searchController.addListener(_filterRestaurants);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getRestaurants();
      final restaurants = List<Map<String, dynamic>>.from(response['restaurants'] ?? []);
      
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden restaurants: $e')),
        );
      }
    }
  }

  void _filterRestaurants() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final matchesSearch = restaurant['name']?.toLowerCase().contains(query) ?? false;
        final matchesFilter = _selectedFilter == 'all' || 
                             restaurant['status'] == _selectedFilter;
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mijn Restaurants'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/cateraar/restaurants/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Zoek restaurants...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.entries.map((entry) {
                      final isSelected = _selectedFilter == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = entry.key;
                            });
                            _filterRestaurants();
                          },
                          backgroundColor: AppColors.background,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Restaurants list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadRestaurants,
                    child: _filteredRestaurants.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredRestaurants.length,
                            itemBuilder: (context, index) {
                              final restaurant = _filteredRestaurants[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildRestaurantCard(restaurant),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty || _selectedFilter != 'all'
                  ? Icons.search_off
                  : Icons.restaurant,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty || _selectedFilter != 'all'
                  ? 'Geen restaurants gevonden'
                  : 'Nog geen restaurants',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty || _selectedFilter != 'all'
                  ? 'Probeer een andere zoekopdracht of filter'
                  : 'Voeg je eerste restaurant toe om te beginnen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isEmpty && _selectedFilter == 'all') ...[
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
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    final status = restaurant['status'] ?? 'active';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/cateraar/restaurants/${restaurant['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image and basic info
              Row(
                children: [
                  // Restaurant image or placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      image: restaurant['image_url'] != null
                          ? DecorationImage(
                              image: NetworkImage(restaurant['image_url']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: restaurant['image_url'] == null
                        ? Icon(
                            Icons.restaurant,
                            color: AppColors.primary,
                            size: 30,
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Restaurant info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                restaurant['name'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        if (restaurant['cuisine_types'] != null)
                          Text(
                            (restaurant['cuisine_types'] as List).join(', '),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                        const SizedBox(height: 4),
                        
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${restaurant['address'] ?? 'Geen adres'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // More options
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, restaurant),
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
                        value: 'menu',
                        child: ListTile(
                          leading: Icon(Icons.menu_book),
                          title: Text('Menu Beheren'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'qr',
                        child: ListTile(
                          leading: Icon(Icons.qr_code),
                          title: Text('QR Code'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'analytics',
                        child: ListTile(
                          leading: Icon(Icons.analytics),
                          title: Text('Analytics'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: status == 'active' ? 'deactivate' : 'activate',
                        child: ListTile(
                          leading: Icon(
                            status == 'active' ? Icons.pause : Icons.play_arrow,
                          ),
                          title: Text(status == 'active' ? 'Deactiveren' : 'Activeren'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Verwijderen', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Stats row
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.star,
                    label: 'Rating',
                    value: '${restaurant['rating'] ?? 0.0}',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    icon: Icons.menu_book,
                    label: 'Menu Items',
                    value: '${restaurant['menu_items_count'] ?? 0}',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    icon: Icons.qr_code_scanner,
                    label: 'QR Scans',
                    value: '${restaurant['qr_scans'] ?? 0}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    icon: Icons.favorite,
                    label: 'Favorieten',
                    value: '${restaurant['favorites_count'] ?? 0}',
                    color: Colors.red,
                  ),
                ],
              ),
              
              if (restaurant['description'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  restaurant['description'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Actief';
      case 'inactive':
        return 'Inactief';
      case 'draft':
        return 'Concept';
      default:
        return 'Onbekend';
    }
  }

  void _handleMenuAction(String action, Map<String, dynamic> restaurant) {
    switch (action) {
      case 'edit':
        context.push('/cateraar/restaurants/${restaurant['id']}/edit');
        break;
      case 'menu':
        context.push('/cateraar/restaurants/${restaurant['id']}/menu');
        break;
      case 'qr':
        context.push('/cateraar/qr-generator?restaurant_id=${restaurant['id']}');
        break;
      case 'analytics':
        context.push('/cateraar/analytics?restaurant_id=${restaurant['id']}');
        break;
      case 'activate':
      case 'deactivate':
        _toggleRestaurantStatus(restaurant);
        break;
      case 'delete':
        _showDeleteConfirmation(restaurant);
        break;
    }
  }

  Future<void> _toggleRestaurantStatus(Map<String, dynamic> restaurant) async {
    final newStatus = restaurant['status'] == 'active' ? 'inactive' : 'active';
    
    try {
      await _apiService.updateRestaurant(
        restaurant['id'],
        {'status': newStatus},
      );
      
      setState(() {
        restaurant['status'] = newStatus;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restaurant ${newStatus == 'active' ? 'geactiveerd' : 'gedeactiveerd'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij wijzigen status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> restaurant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurant Verwijderen'),
        content: Text(
          'Weet je zeker dat je "${restaurant['name']}" wilt verwijderen? '
          'Deze actie kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRestaurant(restaurant);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRestaurant(Map<String, dynamic> restaurant) async {
    try {
      await _apiService.deleteRestaurant(restaurant['id']);
      
      setState(() {
        _restaurants.removeWhere((r) => r['id'] == restaurant['id']);
        _filteredRestaurants.removeWhere((r) => r['id'] == restaurant['id']);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant succesvol verwijderd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij verwijderen restaurant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

