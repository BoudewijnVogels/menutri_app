import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class RestaurantDetailCateraarPage extends ConsumerStatefulWidget {
  final int restaurantId;

  const RestaurantDetailCateraarPage({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailCateraarPage> createState() =>
      _RestaurantDetailCateraarPageState();
}

class _RestaurantDetailCateraarPageState
    extends ConsumerState<RestaurantDetailCateraarPage> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _restaurant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    setState(() => _loading = true);
    try {
      final response =
          await _apiService.getRestaurant(widget.restaurantId); // backend call
      setState(() {
        _restaurant = response['restaurant'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden restaurant: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restaurant Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          if (_restaurant != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await context.push(
                  '/cateraar/restaurants/${_restaurant!['id']}/edit',
                  extra: _restaurant,
                );
                if (updated == true) _loadRestaurant();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _restaurant == null
              ? const Center(child: Text('Geen data gevonden'))
              : RefreshIndicator(
                  onRefresh: _loadRestaurant,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        _restaurant!['naam'] ?? '',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      if (_restaurant!['beschrijving'] != null)
                        Text(
                          _restaurant!['beschrijving'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const Divider(height: 32),
                      _buildDetailRow('Adres', _restaurant!['adres']),
                      _buildDetailRow('Stad', _restaurant!['stad']),
                      _buildDetailRow('Postcode', _restaurant!['postcode']),
                      _buildDetailRow('Telefoon', _restaurant!['telefoon']),
                      _buildDetailRow('E-mail', _restaurant!['email']),
                      _buildDetailRow('Website', _restaurant!['website']),
                      const Divider(height: 32),
                      _buildDetailRow(
                          'Latitude', _restaurant!['latitude']?.toString()),
                      _buildDetailRow(
                          'Longitude', _restaurant!['longitude']?.toString()),
                      _buildDetailRow(
                          'Prijsklasse', _restaurant!['price_range']),
                      _buildDetailRow('Keuken', _restaurant!['cuisine_type']),
                      const Divider(height: 32),
                      _buildSwitchInfo('Bezorging beschikbaar',
                          _restaurant!['has_delivery']),
                      _buildSwitchInfo(
                          'Afhalen beschikbaar', _restaurant!['has_takeaway']),
                      _buildSwitchInfo(
                          'Rolstoeltoegankelijk', _restaurant!['wheelchair']),
                      _buildSwitchInfo('Actief', _restaurant!['actief']),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSwitchInfo(String label, bool? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            value == true ? Icons.check_circle : Icons.cancel,
            color: value == true ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
