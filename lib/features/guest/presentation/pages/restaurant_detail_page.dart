import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

// Belangrijk: alias je modellen om type-verwarring te voorkomen
import '../../../../core/models/restaurant.dart' as models_restaurant;
import '../../../../core/models/menu_item.dart' as models_menu;

class RestaurantDetailPage extends ConsumerStatefulWidget {
  final int restaurantId;

  const RestaurantDetailPage({
    super.key,
    required this.restaurantId,
  });

  @override
  ConsumerState<RestaurantDetailPage> createState() =>
      _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends ConsumerState<RestaurantDetailPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  late PageController _imageController;

  models_restaurant.Restaurant? _restaurant;
  List<models_menu.MenuItem> _menuItems = [];
  List<Map<String, dynamic>> _reviews = [];
  List<String> _images = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _imageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.getRestaurant(widget.restaurantId),
        _apiService.getMenuItems(restaurantId: widget.restaurantId),
        _apiService.getReviews(restaurantId: widget.restaurantId),
        _apiService.getFavorites(),
      ]);

      // --- Restaurant ---
      final restRaw = futures[0];
      final restMap = ((restRaw as Map).containsKey('restaurant'))
          ? Map<String, dynamic>.from((restRaw as Map)['restaurant'])
          : Map<String, dynamic>.from(restRaw as Map);
      final restaurant = models_restaurant.Restaurant.fromJson(restMap);

      // --- Menu items ---
      final miRaw = futures[1];
      List<dynamic> itemsList;
      if (miRaw is List) {
        itemsList = miRaw as List<dynamic>;
      } else {
        final miMap = Map<String, dynamic>.from(miRaw as Map);
        final extracted = (miMap['menu_items'] ??
            miMap['items'] ??
            miMap['data'] ??
            miMap['results'] ??
            []);
        if (extracted is List) {
          itemsList = extracted;
        } else {
          // fallback: vaak is het { data: { items: [] } } of zoiets
          final maybeList = (extracted is Map)
              ? ((extracted['items'] ??
                  extracted['menu_items'] ??
                  extracted['results']) as List?)
              : null;
          itemsList = maybeList ?? <dynamic>[];
        }
      }

      final menuItems = itemsList
          .whereType<dynamic>()
          .map((e) => models_menu.MenuItem.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();

      // --- Reviews ---
      final rvRaw = futures[2];
      Map<String, dynamic> rvMap = Map<String, dynamic>.from(rvRaw as Map);
      final revList = (rvMap['reviews'] ??
              rvMap['data'] ??
              rvMap['results'] ??
              []) as List? ??
          <dynamic>[];
      final reviews =
          revList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // --- Favorites ---
      final favRaw = futures[3];
      final favs = (favRaw['favorites'] ??
              favRaw['data'] ??
              favRaw['results'] ??
              []) as List? ??
          <dynamic>[];
      final isFav = favs.any((f) {
        final m = Map<String, dynamic>.from(f as Map);
        final rid = m['restaurant_id'] ?? m['restaurantId'];
        return rid == widget.restaurantId;
      });

      // --- Images ---
      final images = <String>[];

      // 1) Gallery-lijst
      final gallery = restMap['images'] ?? restMap['gallery'];
      if (gallery is List) {
        for (final g in gallery) {
          final url = (g is String)
              ? g
              : (g is Map ? (g['url'] ?? g['image_url']) : null);
          if (url is String && url.isNotEmpty) images.add(url);
        }
      }

      // 2) Single image velden (optioneel)
      final singleImage = restMap['image'] ??
          restMap['image_url'] ??
          restMap['imageUrl'] ??
          restaurant.imageUrl;

      if (images.isEmpty && singleImage is String && singleImage.isNotEmpty) {
        images.add(singleImage);
      }

      setState(() {
        _restaurant = restaurant;
        _menuItems = menuItems;
        _reviews = reviews;
        _isFavorite = isFav;
        _images = images;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden restaurant: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_restaurant == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Restaurant niet gevonden'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildMenuTab(),
                  _buildReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image carousel: alleen tonen als we URL's hebben
            if (_images.isNotEmpty)
              PageView.builder(
                controller: _imageController,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    _images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surface,
                      child: Icon(
                        Icons.restaurant,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                color: AppColors.surface,
                child: Icon(
                  Icons.restaurant,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.withAlphaFraction(AppColors.black, 0.7),
                  ],
                ),
              ),
            ),

            // Indicatoren
            if (_images.length > 1)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _images.asMap().entries.map((entry) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? Colors.white
                            : AppColors.withAlphaFraction(Colors.white, 0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Overlay met naam, rating, adres, chips
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _restaurant!.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        _restaurant!.rating?.toStringAsFixed(1) ?? '-',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${_reviews.length} reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.withAlphaFraction(
                                  Colors.white, 0.8),
                            ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _restaurant!.address ?? '-',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip(
                          _restaurant!.isOpen ? 'Open' : 'Gesloten',
                          _restaurant!.isOpen ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      if (_restaurant!.deliveryAvailable)
                        _buildStatusChip('Bezorging', Colors.blue),
                      const SizedBox(width: 8),
                      if (_restaurant!.takeawayAvailable)
                        _buildStatusChip('Afhalen', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : AppColors.onPrimary,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareRestaurant,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(text: 'Info (${_restaurant!.cuisineTypes.length})'),
          Tab(text: 'Menu (${_menuItems.length})'),
          Tab(text: 'Reviews (${_reviews.length})'),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact
            _buildInfoCard(
              'Contact Informatie',
              [
                if (_restaurant!.phone != null &&
                    _restaurant!.phone!.isNotEmpty)
                  _buildInfoRow(Icons.phone, 'Telefoon', _restaurant!.phone!,
                      onTap: _callRestaurant),
                if (_restaurant!.email != null &&
                    _restaurant!.email!.isNotEmpty)
                  _buildInfoRow(Icons.email, 'Email', _restaurant!.email!,
                      onTap: _emailRestaurant),
                if (_restaurant!.website != null &&
                    _restaurant!.website!.isNotEmpty)
                  _buildInfoRow(Icons.web, 'Website', _restaurant!.website!,
                      onTap: _openWebsite),
                _buildInfoRow(
                  Icons.access_time,
                  'Openingstijden',
                  _formatOpeningHours(_restaurant!.openingHours),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Over het restaurant
            if (_restaurant!.description != null &&
                _restaurant!.description!.isNotEmpty) ...[
              _buildInfoCard(
                'Over ${_restaurant!.name}',
                [
                  Text(
                    _restaurant!.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Keukentypes
            if (_restaurant!.cuisineTypes.isNotEmpty) ...[
              _buildInfoCard(
                'Keuken Types',
                [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _restaurant!.cuisineTypes
                        .map(
                          (cuisine) => Chip(
                            label: Text(cuisine),
                            backgroundColor: AppColors.withAlphaFraction(
                                AppColors.primary, 0.1),
                            labelStyle: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Voorzieningen
            _buildInfoCard(
              'Voorzieningen',
              [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_restaurant!.deliveryAvailable)
                      _buildFeatureChip(
                          'Bezorging', Icons.delivery_dining, Colors.blue),
                    if (_restaurant!.takeawayAvailable)
                      _buildFeatureChip(
                          'Afhalen', Icons.takeout_dining, Colors.orange),
                    if (_restaurant!.reservationRequired)
                      _buildFeatureChip('Reservering vereist', Icons.event_seat,
                          Colors.purple),
                    _buildFeatureChip(
                        'Toegankelijk', Icons.accessible, Colors.green),
                    _buildFeatureChip('WiFi', Icons.wifi, Colors.teal),
                    _buildFeatureChip(
                        'Parking', Icons.local_parking, Colors.indigo),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Locatie & route
            _buildInfoCard(
              'Locatie & Routebeschrijving',
              [
                if (_restaurant!.latitude != null &&
                    _restaurant!.longitude != null)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _restaurant!.latitude!,
                            _restaurant!.longitude!,
                          ),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('restaurant_${_restaurant!.id}'),
                            position: LatLng(
                              _restaurant!.latitude!,
                              _restaurant!.longitude!,
                            ),
                            infoWindow: InfoWindow(
                              title: _restaurant!.name,
                              snippet: _restaurant!.address ?? '-',
                            ),
                          ),
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          AppColors.withAlphaFraction(AppColors.primary, 0.05),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Text(
                      'Kaart niet beschikbaar',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  _restaurant!.address ?? '-',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_restaurant!.latitude != null &&
                                _restaurant!.longitude != null)
                            ? _openInMaps
                            : null,
                        icon: const Icon(Icons.directions),
                        label: const Text('Routebeschrijving'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_restaurant!.phone != null &&
                                _restaurant!.phone!.isNotEmpty)
                            ? _callRestaurant
                            : null,
                        icon: const Icon(Icons.phone),
                        label: const Text('Bellen'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    if (_menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Geen menu beschikbaar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Het menu wordt binnenkort toegevoegd',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    // Groeperen per categorie
    final groupedItems = <String, List<models_menu.MenuItem>>{};
    for (final item in _menuItems) {
      final category = item.category ?? 'Overig';
      groupedItems[category] = groupedItems[category] ?? [];
      groupedItems[category]!.add(item);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedItems.length,
        itemBuilder: (context, index) {
          final category = groupedItems.keys.elementAt(index);
          final items = groupedItems[category]!;
          return _buildMenuCategory(category, items);
        },
      ),
    );
  }

  Widget _buildReviewsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _reviews.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Geen reviews',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wees de eerste om een review te schrijven!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _writeReview,
                    icon: const Icon(Icons.edit),
                    label: const Text('Review schrijven'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Review summary
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: _buildReviewSummary(),
                ),

                // Reviews list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      return _buildReviewCard(review);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              '$label: ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onTap != null ? AppColors.primary : null,
                      decoration:
                          onTap != null ? TextDecoration.underline : null,
                    ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: AppColors.withAlphaFraction(color, 0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildMenuCategory(String category, List<models_menu.MenuItem> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.withAlphaFraction(AppColors.primary, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildMenuItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(models_menu.MenuItem item) {
    // Bepaal calorie-kleur o.b.v. jouw helper
    Color calorieColor = AppColors.getCalorieMarginColor(0);
    if (item.calories != null) {
      final margin = (item.calories! / 500 * 100) - 100; // referentie 500kcal
      calorieColor = AppColors.getCalorieMarginColor(margin);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                '€${item.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),

          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],

          const SizedBox(height: 8),

          // Voedings- & allergeneninfo
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (item.calories != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.withAlphaFraction(calorieColor, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.calories!.round()} kcal',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: calorieColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              if (item.allergens.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.withAlphaFraction(Colors.orange, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Allergenen: ${item.allergens.join(', ')}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              if (item.isVegetarian)
                _buildDietChip('Vegetarisch', Colors.green),
              if (item.isVegan)
                _buildDietChip('Veganistisch', Colors.lightGreen),
            ],
          ),

          const SizedBox(height: 8),

          // Actieknoppen
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () => _addToFavorites(item),
                tooltip: 'Toevoegen aan favorieten',
                color: AppColors.primary,
              ),
              IconButton(
                icon: const Icon(Icons.restaurant),
                onPressed: () => _markAsEaten(item),
                tooltip: 'Markeren als gegeten',
                color: AppColors.primary,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareMenuItem(item),
                tooltip: 'Delen',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDietChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.withAlphaFraction(color, 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildReviewSummary() {
    final avgRating = _restaurant!.rating;
    final totalReviews = _reviews.length;

    // Verdeling
    final ratingCounts = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingCounts[i] = 0;
    }

    for (final review in _reviews) {
      final rating = (review['rating'] as num?)?.round() ?? 0;
      if (rating >= 1 && rating <= 5) {
        ratingCounts[rating] = ratingCounts[rating]! + 1;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Column(
              children: [
                Text(
                  avgRating?.toStringAsFixed(1) ?? '-',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                Row(
                  children: List.generate(
                      5,
                      (index) => Icon(
                            index < (avgRating ?? 0).round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          )),
                ),
                Text(
                  '$totalReviews reviews',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  for (int i = 5; i >= 1; i--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$i'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: totalReviews > 0
                                  ? (ratingCounts[i]! / totalReviews)
                                  : 0,
                              backgroundColor: AppColors.outline,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.amber),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${ratingCounts[i]}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _writeReview,
            icon: const Icon(Icons.edit),
            label: const Text('Review schrijven'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = (review['comment'] as String?) ?? '';
    final userName = (review['user_name'] as String?) ?? 'Anoniem';
    final createdAtStr = review['created_at'] as String?;
    final createdAt =
        createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                    style: TextStyle(color: AppColors.onPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                              5,
                              (index) => Icon(
                                    index < rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  )),
                          const SizedBox(width: 8),
                          if (createdAt != null)
                            Text(
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'qr_scan',
          onPressed: _scanQRCode,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.qr_code_scanner),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: 'share',
          onPressed: _shareRestaurant,
          backgroundColor: AppColors.secondary,
          icon: const Icon(Icons.share),
          label: const Text('Delen'),
        ),
      ],
    );
  }

  String _formatOpeningHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return 'Niet beschikbaar';

    final today = DateTime.now().weekday;
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final todayName = dayNames[today - 1];

    if (openingHours.containsKey(todayName)) {
      final todayHours = openingHours[todayName];
      if (todayHours is Map &&
          todayHours.containsKey('open') &&
          todayHours.containsKey('close')) {
        return 'Vandaag: ${todayHours['open']} - ${todayHours['close']}';
      }
    }

    return 'Ma-Zo: 09:00-22:00'; // Fallback
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        // zoek favorite-id voor dit restaurant en verwijder
        final favData = await _apiService.getFavorites();
        final favList = (favData['favorites'] ??
                favData['data'] ??
                favData['results'] ??
                []) as List? ??
            <dynamic>[];
        final target =
            favList.cast<Map>().cast<Map<String, dynamic>>().firstWhere(
                  (f) =>
                      (f['restaurant_id'] ?? f['restaurantId']) ==
                      widget.restaurantId,
                  orElse: () => {},
                );
        final favId = target['id'];
        if (favId != null) {
          await _apiService.deleteFavorite(favId);
          setState(() => _isFavorite = false);
        }
      } else {
        await _apiService.addFavorite(restaurantId: widget.restaurantId);
        setState(() => _isFavorite = true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite
                ? 'Restaurant toegevoegd aan favorieten'
                : 'Restaurant verwijderd uit favorieten'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij wijzigen favoriet: $e')),
        );
      }
    }
  }

  Future<void> _shareRestaurant() async {
    try {
      final shareUrl = 'https://menutri.nl/restaurant/${widget.restaurantId}';

      final text = 'Bekijk ${_restaurant!.name} op Menutri!\n\n'
          '${_restaurant!.description ?? ''}\n\n'
          '📍 ${_restaurant!.address ?? '-'}\n'
          '⭐ ${_restaurant!.rating?.toStringAsFixed(1) ?? '-'} sterren\n\n'
          '$shareUrl';

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Restaurant: ${_restaurant!.name}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij delen: $e')),
        );
      }
    }
  }

  Future<void> _shareMenuItem(models_menu.MenuItem item) async {
    try {
      // NB: als 'price' non-nullable is in je model (double), geen null-check meer doen.
      final priceText = '€${item.price.toStringAsFixed(2)}';

      final caloriesText =
          (item.calories != null) ? '🔥 ${item.calories!.round()} kcal\n' : '';

      final text = 'Bekijk dit gerecht: ${item.name}\n\n'
          '${item.description ?? ''}\n\n'
          '$caloriesText'
          '💰 $priceText\n\n'
          'Bij ${_restaurant!.name}\n'
          'https://menutri.nl/restaurant/${widget.restaurantId}';

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Gerecht: ${item.name}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij delen: $e')),
        );
      }
    }
  }

  Future<void> _openInMaps() async {
    try {
      final lat = _restaurant!.latitude;
      final lng = _restaurant!.longitude;
      if (lat == null || lng == null) {
        throw 'Locatie onbekend';
      }
      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Kon $url niet openen';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij openen kaart: $e')),
        );
      }
    }
  }

  Future<void> _callRestaurant() async {
    final phone = _restaurant!.phone;
    if (phone == null || phone.isEmpty) return;

    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Kon $phone niet bellen';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij bellen: $e')),
        );
      }
    }
  }

  Future<void> _emailRestaurant() async {
    final email = _restaurant!.email;
    if (email == null || email.isEmpty) return;

    try {
      final uri = Uri.parse('mailto:$email');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Kon e-mailapp niet openen';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij e-mailen: $e')),
        );
      }
    }
  }

  Future<void> _openWebsite() async {
    final site = _restaurant!.website;
    if (site == null || site.isEmpty) return;

    try {
      final uri = Uri.parse(site);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Kon website niet openen';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij openen website: $e')),
        );
      }
    }
  }

  Future<void> _addToFavorites(models_menu.MenuItem item) async {
    try {
      await _apiService.addFavorite(menuItemId: item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} toegevoegd aan favorieten')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij toevoegen favoriet: $e')),
        );
      }
    }
  }

  Future<void> _markAsEaten(models_menu.MenuItem item) async {
    try {
      await _apiService.addEaten(menuItemId: item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} gemarkeerd als gegeten')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij markeren als gegeten: $e')),
        );
      }
    }
  }

  void _scanQRCode() {
    Navigator.pushNamed(context, '/qr-scanner');
  }

  void _writeReview() {
    showDialog(
      context: context,
      builder: (context) => _ReviewDialog(
        restaurantId: widget.restaurantId,
        restaurantName: _restaurant!.name,
        onReviewSubmitted: () {
          _loadData(); // Refresh reviews
        },
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;
  final VoidCallback onReviewSubmitted;

  const _ReviewDialog({
    required this.restaurantId,
    required this.restaurantName,
    required this.onReviewSubmitted,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review voor ${widget.restaurantName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Geef een beoordeling:'),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Jouw review (optioneel)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _rating == 0 ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Versturen'),
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    try {
      await _apiService.createReview({
        'restaurant_id': widget.restaurantId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review succesvol verstuurd!')),
        );
        widget.onReviewSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij versturen review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
