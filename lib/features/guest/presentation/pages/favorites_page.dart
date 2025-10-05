import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _favorites = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await ApiService().getFavorites();
      final favorites = response is List
          ? response
          : (response['favorites'] as List<dynamic>? ?? []);

      setState(() {
        _favorites = favorites as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kon favorieten niet laden';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorieten'),
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.mediumBrown,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.mediumBrown,
          tabs: const [
            Tab(text: 'Restaurants'),
            Tab(text: 'Gerechten'),
            Tab(text: 'Collecties'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRestaurantFavorites(),
          _buildDishFavorites(),
          _buildCollections(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mediumBrown,
        onPressed: _showCreateCollectionDialog,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildRestaurantFavorites() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final restaurantFavorites =
        _favorites.where((fav) => fav['restaurant_id'] != null).toList();

    if (restaurantFavorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_outlined,
        title: 'Geen favoriete restaurants',
        subtitle:
            'Voeg restaurants toe aan je favorieten door op het hartje te tikken',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: restaurantFavorites.length,
        itemBuilder: (context, index) {
          final favorite = restaurantFavorites[index];
          return _buildRestaurantFavoriteCard(favorite);
        },
      ),
    );
  }

  Widget _buildDishFavorites() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final dishFavorites =
        _favorites.where((fav) => fav['menu_item_id'] != null).toList();

    if (dishFavorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_outlined,
        title: 'Geen favoriete gerechten',
        subtitle: 'Voeg gerechten toe aan je favorieten tijdens het browsen',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dishFavorites.length,
        itemBuilder: (context, index) {
          final favorite = dishFavorites[index];
          return _buildDishFavoriteCard(favorite);
        },
      ),
    );
  }

  Widget _buildCollections() {
    final collections = <String, List<dynamic>>{};
    for (final fav in _favorites) {
      final collectionName = fav['collection_name'] ?? 'Standaard';
      collections[collectionName] = collections[collectionName] ?? [];
      collections[collectionName]!.add(fav);
    }

    if (collections.isEmpty) {
      return _buildEmptyState(
        icon: Icons.collections_outlined,
        title: 'Geen collecties',
        subtitle: 'Maak collecties om je favorieten te organiseren',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final collectionName = collections.keys.elementAt(index);
          final items = collections[collectionName]!;
          return _buildCollectionCard(collectionName, items);
        },
      ),
    );
  }

  Widget _buildRestaurantFavoriteCard(Map<String, dynamic> favorite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (favorite['restaurant_id'] != null) {
            context.push('/guest/restaurant/${favorite['restaurant_id']}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.mediumBrown,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant, color: AppColors.white),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite['restaurant_name'] ?? 'Restaurant',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (favorite['notes'] != null)
                      Text(
                        favorite['notes'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Toegevoegd op ${_formatDate(favorite['created_at'])}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.grey,
                          ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: AppColors.mediumBrown),
                        SizedBox(width: 8),
                        Text('Delen'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Verwijderen'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeFavorite(favorite['id']);
                  } else if (value == 'share') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delen komt binnenkort')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDishFavoriteCard(Map<String, dynamic> favorite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.mediumBrown,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant, color: AppColors.white),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite['menu_item_name'] ?? 'Gerecht',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    favorite['restaurant_name'] ?? 'Restaurant',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey,
                        ),
                  ),
                  if (favorite['notes'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      favorite['notes'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Toegevoegd op ${_formatDate(favorite['created_at'])}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.grey,
                        ),
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: AppColors.mediumBrown),
                      SizedBox(width: 8),
                      Text('Delen'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Verwijderen'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  _removeFavorite(favorite['id']);
                } else if (value == 'share') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delen komt binnenkort')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(String collectionName, List<dynamic> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Collection icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.mediumBrown,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.collections, color: AppColors.white),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collectionName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${items.length} item${items.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey,
                          ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/guest/search'),
            child: const Text('Restaurants ontdekken'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFavorites,
            child: const Text('Opnieuw proberen'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFavorite(int favoriteId) async {
    try {
      await ApiService().deleteFavorite(favoriteId);
      await _loadFavorites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favoriet verwijderd'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kon favoriet niet verwijderen'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCreateCollectionDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuwe collectie'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Collectie naam',
            hintText: 'Bijv. "Favoriete pizza\'s"',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Collectie aanmaken komt binnenkort')),
                );
              }
            },
            child: const Text('Aanmaken'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Onbekend';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Onbekend';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
