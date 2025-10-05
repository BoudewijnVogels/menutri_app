import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class EditMenuItemPage extends ConsumerStatefulWidget {
  final int itemId;

  const EditMenuItemPage({super.key, required this.itemId});

  @override
  ConsumerState<EditMenuItemPage> createState() => _EditMenuItemPageState();
}

class _EditMenuItemPageState extends ConsumerState<EditMenuItemPage> {
  final ApiService _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _available = true;
  bool _isLoading = true;
  bool _saving = false;

  bool _useRecipe = false;
  Map<String, dynamic>? _selectedRecipe;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    try {
      final resp = await _apiService.getMenuItem(widget.itemId);
      final item = resp['menu_item'] ?? {};

      setState(() {
        _nameController.text = item['name'] ?? '';
        _descriptionController.text = item['description'] ?? '';
        _priceController.text = (item['price']?.toString() ?? '');
        _available = item['available'] ?? true;

        if (item['recipe'] != null || item['recipe_id'] != null) {
          _useRecipe = true;
          _selectedRecipe = item['recipe'] ??
              {
                "id": item['recipe_id'],
                "name": "(Recept ID: ${item['recipe_id']})"
              };
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij laden menu-item: $e")),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final data = {
        "name": _nameController.text,
        "price": double.tryParse(_priceController.text) ?? 0,
        "description": _descriptionController.text,
        "available": _available,
        "recipe_id": _useRecipe ? (_selectedRecipe?['id']) : null,
      };

      await _apiService.updateMenuItem(widget.itemId, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Menu item bijgewerkt")),
        );
        context.pop(true); // refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij opslaan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickRecipe() async {
    final recipe = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _RecipePickerDialog(),
    );

    if (recipe != null) {
      setState(() {
        _selectedRecipe = recipe;
        _nameController.text = recipe['name'] ?? '';
        _descriptionController.text = recipe['description'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Menu Item bewerken"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Gebaseerd op recept"),
                      value: _useRecipe,
                      onChanged: (val) {
                        setState(() {
                          _useRecipe = val;
                          if (!val) _selectedRecipe = null;
                        });
                      },
                    ),
                    if (_useRecipe) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.book),
                        label: Text(
                          (_selectedRecipe != null)
                              ? "Gekozen: ${_selectedRecipe!['name']}"
                              : "Kies recept",
                        ),
                        onPressed: _pickRecipe,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Naam",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Naam is verplicht" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: "Prijs (€)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Prijs is verplicht" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Beschrijving",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("Beschikbaar"),
                      value: _available,
                      onChanged: (v) => setState(() => _available = v),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text("Opslaan"),
                        onPressed: _saving ? null : _saveItem,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// -------------------
// RecipePicker Dialog
// -------------------
class _RecipePickerDialog extends ConsumerStatefulWidget {
  const _RecipePickerDialog();

  @override
  ConsumerState<_RecipePickerDialog> createState() =>
      _RecipePickerDialogState();
}

class _RecipePickerDialogState extends ConsumerState<_RecipePickerDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes([String? query]) async {
    setState(() => _loading = true);
    try {
      final resp = await _apiService.getRecipes();
      final list = List<Map<String, dynamic>>.from(resp['recipes'] ?? []);
      setState(() {
        _recipes = query == null || query.isEmpty
            ? list
            : list
                .where((r) => (r['name'] ?? '')
                    .toLowerCase()
                    .contains(query.toLowerCase()))
                .toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij laden recepten: $e")),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Kies een recept"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Zoek recept...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _loadRecipes(value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _recipes.length,
                      itemBuilder: (context, i) {
                        final recipe = _recipes[i];
                        return ListTile(
                          leading: const Icon(Icons.restaurant),
                          title: Text(recipe['name'] ?? ''),
                          subtitle: Text(
                              recipe['description'] ?? 'Geen beschrijving'),
                          onTap: () => Navigator.pop(context, recipe),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuleren"),
        ),
      ],
    );
  }
}
