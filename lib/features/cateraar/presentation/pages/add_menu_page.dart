import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class AddMenuPage extends ConsumerStatefulWidget {
  const AddMenuPage({super.key});

  @override
  ConsumerState<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends ConsumerState<AddMenuPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _status = 'concept';
  bool _isSaving = false;

  // Restaurant selectie
  int? _selectedRestaurantId;
  List<Map<String, dynamic>> _restaurants = [];
  bool _loadingRestaurants = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final resp = await _apiService.getRestaurants();
      final list = List<Map<String, dynamic>>.from(resp['restaurants'] ?? []);

      setState(() {
        _restaurants = list;
        _loadingRestaurants = false;

        // fallback: selecteer automatisch als er maar één restaurant is
        if (list.length == 1) {
          _selectedRestaurantId = list.first['id'];
        }
      });
    } catch (e) {
      setState(() => _loadingRestaurants = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij laden restaurants: $e")),
        );
      }
    }
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final response = await _apiService.createMenu(
        restaurantId: _selectedRestaurantId!,
        name: _nameController.text.trim(), // ✅ Engels veld
        status: _status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menukaart aangemaakt'),
            backgroundColor: Colors.green,
          ),
        );

        final id = response['id'];
        if (id != null) {
          context.go('/cateraar/menus/$id');
        } else {
          context.go('/cateraar/menus');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij aanmaken menukaart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nieuwe menukaart'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Naam menukaart',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Voer een naam in';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Restaurant selectie
              _loadingRestaurants
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      initialValue: _selectedRestaurantId,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant',
                        border: OutlineInputBorder(),
                      ),
                      items: _restaurants.map<DropdownMenuItem<int>>((r) {
                        return DropdownMenuItem<int>(
                          value: r['id'] as int,
                          child: Text(r['name'] ?? 'Onbekend'), // ✅ Engels veld
                        );
                      }).toList(),
                      validator: (val) =>
                          val == null ? 'Kies een restaurant' : null,
                      onChanged: (val) {
                        setState(() => _selectedRestaurantId = val);
                      },
                    ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'concept', child: Text('Concept')),
                  DropdownMenuItem(value: 'active', child: Text('Actief')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactief')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Bezig...' : 'Opslaan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
