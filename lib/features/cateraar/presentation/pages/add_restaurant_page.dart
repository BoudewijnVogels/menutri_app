import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class AddRestaurantPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingRestaurant;

  const AddRestaurantPage({super.key, this.existingRestaurant});

  @override
  ConsumerState<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends ConsumerState<AddRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Tekstcontrollers
  final _naamController = TextEditingController();
  final _beschrijvingController = TextEditingController();
  final _adresController = TextEditingController();
  final _stadController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _telefoonController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Keuzes / booleans
  bool _hasDelivery = false;
  bool _hasTakeaway = false;
  bool _isWheelchairAccessible = false;
  bool _actief = true;

  String? _priceRange;
  String? _cuisineType;

  bool _loading = false;

  final List<String> _priceRanges = ['€', '€€', '€€€', '€€€€'];
  final List<String> _cuisineTypes = [
    'dutch',
    'italian',
    'french',
    'chinese',
    'indian',
    'japanese',
    'mexican',
    'thai',
    'greek',
    'american',
    'mediterranean',
    'fusion',
    'vegetarian',
    'vegan',
    'fast_food',
    'fine_dining',
    'cafe',
    'bakery',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingRestaurant != null) {
      final r = widget.existingRestaurant!;
      _naamController.text = r['naam'] ?? '';
      _beschrijvingController.text = r['beschrijving'] ?? '';
      _adresController.text = r['adres'] ?? '';
      _stadController.text = r['stad'] ?? '';
      _postcodeController.text = r['postcode'] ?? '';
      _telefoonController.text = r['telefoon'] ?? '';
      _emailController.text = r['email'] ?? '';
      _websiteController.text = r['website'] ?? '';
      _latitudeController.text = r['latitude']?.toString() ?? '';
      _longitudeController.text = r['longitude']?.toString() ?? '';
      _hasDelivery = r['has_delivery'] ?? false;
      _hasTakeaway = r['has_takeaway'] ?? false;
      _isWheelchairAccessible = r['wheelchair'] ?? false;
      _actief = r['actief'] ?? true;
      _priceRange = r['price_range'];
      _cuisineType = r['cuisine_type'];
    }
  }

  @override
  void dispose() {
    _naamController.dispose();
    _beschrijvingController.dispose();
    _adresController.dispose();
    _stadController.dispose();
    _postcodeController.dispose();
    _telefoonController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final restaurantData = {
      'naam': _naamController.text.trim(),
      'beschrijving': _beschrijvingController.text.trim(),
      'adres': _adresController.text.trim(),
      'stad': _stadController.text.trim(),
      'postcode': _postcodeController.text.trim(),
      'telefoon': _telefoonController.text.trim(),
      'email': _emailController.text.trim(),
      'website': _websiteController.text.trim(),
      'latitude': double.tryParse(_latitudeController.text.trim()),
      'longitude': double.tryParse(_longitudeController.text.trim()),
      'has_delivery': _hasDelivery,
      'has_takeaway': _hasTakeaway,
      'is_wheelchair_accessible': _isWheelchairAccessible,
      'actief': _actief,
      'price_range': _priceRange,
      'cuisine_type': _cuisineType,
    };

    try {
      if (widget.existingRestaurant == null) {
        await _apiService.createRestaurant(restaurantData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Restaurant toegevoegd")),
          );
        }
      } else {
        await _apiService.updateRestaurant(
          widget.existingRestaurant!['id'],
          restaurantData,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Restaurant bijgewerkt")),
          );
        }
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij opslaan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRestaurant != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? "Restaurant bewerken" : "Nieuw restaurant"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _naamController,
                decoration: const InputDecoration(labelText: "Naam *"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Naam is verplicht" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _beschrijvingController,
                decoration: const InputDecoration(labelText: "Beschrijving"),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adresController,
                decoration: const InputDecoration(labelText: "Adres"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stadController,
                decoration: const InputDecoration(labelText: "Stad"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _postcodeController,
                decoration: const InputDecoration(labelText: "Postcode"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefoonController,
                decoration: const InputDecoration(labelText: "Telefoon"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "E-mail"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: "Website"),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(labelText: "Latitude"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(labelText: "Longitude"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _priceRange,
                items: _priceRanges
                    .map((pr) => DropdownMenuItem(value: pr, child: Text(pr)))
                    .toList(),
                onChanged: (val) => setState(() => _priceRange = val),
                decoration: const InputDecoration(labelText: "Prijsklasse"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _cuisineType,
                items: _cuisineTypes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _cuisineType = val),
                decoration: const InputDecoration(labelText: "Keuken"),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text("Bezorging beschikbaar"),
                value: _hasDelivery,
                onChanged: (v) => setState(() => _hasDelivery = v),
              ),
              SwitchListTile(
                title: const Text("Afhalen beschikbaar"),
                value: _hasTakeaway,
                onChanged: (v) => setState(() => _hasTakeaway = v),
              ),
              SwitchListTile(
                title: const Text("Rolstoeltoegankelijk"),
                value: _isWheelchairAccessible,
                onChanged: (v) => setState(() => _isWheelchairAccessible = v),
              ),
              SwitchListTile(
                title: const Text("Actief"),
                value: _actief,
                onChanged: (v) => setState(() => _actief = v),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveRestaurant,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? "Opslaan" : "Toevoegen"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
