// voor debugPrint
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  bool _showMap = false;
  bool _isLoading = false;
  List<dynamic> _restaurants = [];
  Position? _currentPosition;
  Set<Marker> _markers = {};

  // Filter states
  final List<String> _selectedCuisines = [];
  final List<int> _selectedPriceRanges = [];
  bool _openNowOnly = false;
  bool _suitableForMeOnly = false;

  final List<String> _cuisineTypes = [
    'Italiaans',
    'Chinees',
    'Indiaas',
    'Mexicaans',
    'Frans',
    'Japans',
    'Thais',
    'Grieks',
    'Turks',
    'Amerikaans',
    'Vegetarisch',
    'Vegan'
  ];

  final List<String> _priceRangeLabels = ['€', '€€', '€€€', '€€€€'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchRestaurants();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      _searchRestaurants();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _searchRestaurants() async {
    setState(() => _isLoading = true);

    try {
      if (_currentPosition == null) {
        await _getCurrentLocation();
        if (_currentPosition == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final resp = await ApiService().searchRestaurants(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        radius: 10.0,
        openNow: _openNowOnly ? true : null,
        // Mapping van jouw UI-filters:
        priceRange: _selectedPriceRanges.isNotEmpty
            ? _selectedPriceRanges
                .map((i) => _priceRangeLabels[i - 1])
                .join(',')
            : null,
        cuisine: _selectedCuisines.isNotEmpty ? _selectedCuisines.first : null,
        // Let op: in jouw model had je ook delivery/takeaway/wheelchair,
        // die kun je hier later koppelen aan extra switches in de UI
      );

      // Haal de lijst restaurants veilig uit de Map
      final list = (resp['restaurants'] ??
              resp['data'] ??
              resp['results'] ??
              resp['items'] ??
              []) as List? ??
          [];

      setState(() {
        _restaurants = list.cast<Map<String, dynamic>>();
        _isLoading = false;
      });

      _updateMapMarkers();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij zoeken: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};

    for (int i = 0; i < _restaurants.length; i++) {
      final dynamic r = _restaurants[i];
      if (r is! Map) continue;
      final restaurant = r.cast<String, dynamic>();

      final lat = (restaurant['latitude'] as num?)?.toDouble();
      final lng = (restaurant['longitude'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('${restaurant['id']}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: (restaurant['name'] ?? restaurant['naam'] ?? 'Restaurant')
                  .toString(),
              snippet:
                  '${(restaurant['cuisine_type'] ?? restaurant['cuisineType'] ?? '')} • ${_getPriceRange(restaurant['price_range'] is int ? restaurant['price_range'] as int : null)}',
              onTap: () =>
                  context.push('/guest/restaurant/${restaurant['id']}'),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _isOpen(restaurant)
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoeken'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar and filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Zoek restaurants, gerechten...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchRestaurants();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.lightGrey,
                  ),
                  onSubmitted: (_) => _searchRestaurants(),
                ),

                const SizedBox(height: 12),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Filters',
                        Icons.tune,
                        onTap: _showFiltersBottomSheet,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Open nu',
                        Icons.access_time,
                        isSelected: _openNowOnly,
                        onTap: () {
                          setState(() {
                            _openNowOnly = !_openNowOnly;
                          });
                          _searchRestaurants();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Geschikt voor mij',
                        Icons.favorite,
                        isSelected: _suitableForMeOnly,
                        onTap: () {
                          setState(() {
                            _suitableForMeOnly = !_suitableForMeOnly;
                          });
                          _searchRestaurants();
                        },
                      ),
                      if (_selectedCuisines.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Keuken (${_selectedCuisines.length})',
                          Icons.restaurant,
                          isSelected: true,
                          onTap: _showFiltersBottomSheet,
                        ),
                      ],
                      if (_selectedPriceRanges.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Prijs (${_selectedPriceRanges.length})',
                          Icons.euro,
                          isSelected: true,
                          onTap: _showFiltersBottomSheet,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: _showMap ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon,
      {bool isSelected = false, VoidCallback? onTap}) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap?.call(),
      selectedColor: AppColors.withAlphaFraction(AppColors.mediumBrown, 0.3),
      checkmarkColor: AppColors.mediumBrown,
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              'Geen restaurants gevonden',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Probeer andere zoektermen of filters'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _searchRestaurants,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final dynamic r = _restaurants[index];
          // Zorg dat we een Map hebben voor de card
          final restaurant =
              (r is Map) ? r.cast<String, dynamic>() : <String, dynamic>{};

          return _buildRestaurantCard(restaurant);
        },
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    final distance = _calculateDistance(restaurant);

    // Foto ophalen (String of Map met url/image_url)
    String? primaryPhotoUrl;
    final photos = restaurant['photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) {
        primaryPhotoUrl = first;
      } else if (first is Map) {
        final m = first.cast<String, dynamic>();
        primaryPhotoUrl =
            (m['url'] ?? m['image_url'] ?? m['image'])?.toString();
      }
    }

    final displayName =
        (restaurant['name'] ?? restaurant['naam'] ?? 'Restaurant').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/guest/restaurant/${restaurant['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Restaurant image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.lightBrown,
                  child: (primaryPhotoUrl != null && primaryPhotoUrl.isNotEmpty)
                      ? Image.network(
                          primaryPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.restaurant,
                              color: AppColors.mediumBrown,
                            );
                          },
                        )
                      : const Icon(
                          Icons.restaurant,
                          color: AppColors.mediumBrown,
                        ),
                ),
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
                            displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () =>
                              _toggleFavorite((restaurant['id'] as int?) ?? -1),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          (restaurant['cuisine_type'] ??
                                  restaurant['cuisineType'] ??
                                  'Restaurant')
                              .toString(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${_getPriceRange(restaurant['price_range'] is int ? restaurant['price_range'] as int : null)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey,
                                  ),
                        ),
                        if (distance != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${distance.toStringAsFixed(1)} km',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey,
                                    ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Rating
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              (restaurant['rating'] as num?)
                                      ?.toStringAsFixed(1) ??
                                  '0.0',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Open/Closed status
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isOpen(restaurant)
                                ? AppColors.success
                                : AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isOpen(restaurant) ? 'Open' : 'Gesloten',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
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

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Locatie ophalen...'),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 14,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      onTap: (LatLng position) {
        // optional
      },
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedCuisines.clear();
                        _selectedPriceRanges.clear();
                        _openNowOnly = false;
                        _suitableForMeOnly = false;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cuisine types
                      Text(
                        'Keuken',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _cuisineTypes.map((cuisine) {
                          final isSelected =
                              _selectedCuisines.contains(cuisine);
                          return FilterChip(
                            label: Text(cuisine),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedCuisines.add(cuisine);
                                } else {
                                  _selectedCuisines.remove(cuisine);
                                }
                              });
                            },
                            selectedColor: AppColors.withAlphaFraction(
                                AppColors.mediumBrown, 0.3),
                            checkmarkColor: AppColors.mediumBrown,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Price range
                      Text(
                        'Prijsklasse',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(4, (index) {
                          final priceRange = index + 1;
                          final isSelected =
                              _selectedPriceRanges.contains(priceRange);
                          return FilterChip(
                            label: Text(_priceRangeLabels[index]),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedPriceRanges.add(priceRange);
                                } else {
                                  _selectedPriceRanges.remove(priceRange);
                                }
                              });
                            },
                            selectedColor: AppColors.withAlphaFraction(
                                AppColors.mediumBrown, 0.3),
                            checkmarkColor: AppColors.mediumBrown,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      // main state kan hier worden gesynchroniseerd indien nodig
                    });
                    _searchRestaurants();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mediumBrown,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Filters toepassen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriceRange(int? priceRange) {
    switch (priceRange) {
      case 1:
        return '€';
      case 2:
        return '€€';
      case 3:
        return '€€€';
      case 4:
        return '€€€€';
      default:
        return '€€';
    }
  }

  bool _isOpen(Map<String, dynamic> restaurant) {
    // Mock implementatie - vervang met echte openingstijden als die er zijn
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 9 && hour <= 22;
  }

  double? _calculateDistance(Map<String, dynamic> restaurant) {
    if (_currentPosition == null) return null;

    final lat = (restaurant['latitude'] as num?)?.toDouble();
    final lng = (restaurant['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) return null;

    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        ) /
        1000; // km
  }

  Future<void> _toggleFavorite(int restaurantId) async {
    try {
      await ApiService().addFavorite(restaurantId: restaurantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant toegevoegd aan favorieten'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kon niet toevoegen aan favorieten: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
