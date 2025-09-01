import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/restaurant.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<Restaurant> _nearbyRestaurants = [];
  List<Restaurant> _recommendedRestaurants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load nearby restaurants (mock data for now)
      final response = await ApiService().getRestaurants(perPage: 10);
      final restaurantList = response['restaurants'] as List;

      setState(() {
        _nearbyRestaurants =
            restaurantList.map((json) => Restaurant.fromJson(json)).toList();
        _recommendedRestaurants = _nearbyRestaurants.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kon restaurants niet laden';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.white,
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goedemorgen! 👋',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'Wat ga je vandaag eten?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey,
                          ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner,
                        color: AppColors.mediumBrown),
                    onPressed: () => context.push(AppRoutes.qrScanner),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.mediumBrown),
                    onPressed: () {
                      // TODO: Navigate to notifications
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Notificaties komen binnenkort')),
                      );
                    },
                  ),
                ],
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.guestSearch),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightBrown),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.grey),
                          const SizedBox(width: 12),
                          Text(
                            'Zoek restaurants, gerechten...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Quick actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.qr_code_scanner,
                          label: 'QR Scannen',
                          onTap: () => context.push(AppRoutes.qrScanner),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.map_outlined,
                          label: 'Kaart',
                          onTap: () => context.go(AppRoutes.guestSearch),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.favorite_outline,
                          label: 'Favorieten',
                          onTap: () => context.go(AppRoutes.guestFavorites),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Personalized recommendations
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Voor jou aanbevolen',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.healthProfile),
                        child: const Text('Profiel instellen'),
                      ),
                    ],
                  ),
                ),
              ),

              // Recommendations list
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(_errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Opnieuw proberen'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _recommendedRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = _recommendedRestaurants[index];
                        return _buildRecommendationCard(restaurant);
                      },
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Nearby restaurants
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'In de buurt',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.guestSearch),
                        child: const Text('Alles bekijken'),
                      ),
                    ],
                  ),
                ),
              ),

              // Nearby restaurants list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final restaurant = _nearbyRestaurants[index];
                    return _buildRestaurantListItem(restaurant);
                  },
                  childCount: _nearbyRestaurants.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      AppColors.withAlphaFraction(AppColors.mediumBrown, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.mediumBrown,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Restaurant restaurant) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/guest/restaurant/${restaurant.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.lightBrown,
                  image: restaurant.primaryPhoto.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(restaurant.primaryPhoto),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: restaurant.primaryPhoto.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: AppColors.mediumBrown,
                        ),
                      )
                    : null,
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.naam,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (restaurant.rating != null) ...[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          restaurant.priceRangeDisplay,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey,
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
      ),
    );
  }

  Widget _buildRestaurantListItem(Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/guest/restaurant/${restaurant.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.lightBrown,
                  borderRadius: BorderRadius.circular(8),
                  image: restaurant.primaryPhoto.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(restaurant.primaryPhoto),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: restaurant.primaryPhoto.isEmpty
                    ? const Icon(
                        Icons.restaurant,
                        color: AppColors.mediumBrown,
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.naam,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (restaurant.beschrijving != null)
                      Text(
                        restaurant.beschrijving!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (restaurant.rating != null) ...[
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          restaurant.priceRangeDisplay,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: restaurant.isOpen
                                ? AppColors.success
                                : AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            restaurant.statusText,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.white,
                                ),
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
      ),
    );
  }
}
