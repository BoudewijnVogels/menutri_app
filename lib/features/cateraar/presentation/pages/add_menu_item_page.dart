import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class AddMenuItemPage extends ConsumerStatefulWidget {
  final int menuId;

  const AddMenuItemPage({super.key, required this.menuId});

  @override
  ConsumerState<AddMenuItemPage> createState() => _AddMenuItemPageState();
}

class _AddMenuItemPageState extends ConsumerState<AddMenuItemPage> {
  final ApiService _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newCategoryController = TextEditingController();

  int? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _available = true;
  bool _isLoading = false;
  bool _showNewCategoryField = false;

  // Recipe koppeling
  bool _useRecipe = false;
  Map<String, dynamic>? _selectedRecipe;

  // Categories
  List<Map<String, dynamic>> _categories = [];

  // Ingredients
  List<Map<String, dynamic>> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.getCategories(menuId: widget.menuId);
      setState(() {
        _categories =
            List<Map<String, dynamic>>.from(response['categories'] ?? []);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij laden categorieën: $e")),
        );
      }
    }
  }

  Future<void> _createNewCategory() async {
    if (_newCategoryController.text.trim().isEmpty) return;

    try {
      final response = await _apiService.createCategory({
        'menu_id': widget.menuId,
        'name': _newCategoryController.text.trim(),
      });

      final newCategory = response['category'];
      setState(() {
        _categories.add(newCategory);
        _selectedCategoryId = newCategory['id'];
        _showNewCategoryField = false;
        _newCategoryController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Categorie aangemaakt en geselecteerd")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij aanmaken categorie: $e")),
        );
      }
    }
  }

  Future<void> _saveMenuItem({bool saveAndNext = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        "menu_id": widget.menuId,
        "name": _nameController.text.trim(),
        "price": double.tryParse(_priceController.text) ?? 0,
        "description": _descriptionController.text.trim(),
        // Zowel category_id als category meesturen — backend ondersteunt beide
        if (_selectedCategoryId != null) "category_id": _selectedCategoryId,
        if (_selectedCategoryName != null && _selectedCategoryName!.isNotEmpty)
          "category": _selectedCategoryName,
        "available": _available,
        if (_selectedRecipe != null) "recipe_id": _selectedRecipe!['id'],
        // Ingrediënten veilig mappen
        "ingredients": _ingredients
            .map((ing) => {
                  "ingredient_id": ing['ingredient']?['id'],
                  "quantity": ing['quantity'] ?? 1.0,
                  "unit": ing['unit'] ?? 'gram',
                  "notes": ing['notes'] ?? '',
                })
            .toList(),
      };

      await _apiService.createMenuItem(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menu-item toegevoegd")),
      );

      if (saveAndNext) {
        // Reset het formulier voor het volgende gerecht
        _nameController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _selectedRecipe = null;
        _useRecipe = false;
        _ingredients.clear();
        setState(() {
          _selectedCategoryId = null;
          _selectedCategoryName = null;
        });
      } else {
        context.pop(true); // Terug naar menu-lijst met refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij opslaan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _addIngredient() {
    setState(() {
      _ingredients.add({
        'ingredient': null,
        'quantity': 1.0,
        'unit': 'gram',
        'notes': '',
      });
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _searchIngredientByBarcode(int index) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const _BarcodeScannerDialog(),
    );

    if (result != null) {
      try {
        final response = await _apiService.lookupIngredientByBarcode(result);
        final ingredient = response['ingredient'];

        if (ingredient != null) {
          setState(() {
            _ingredients[index]['ingredient'] = ingredient;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("Ingrediënt gevonden: ${ingredient['name']}")),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Geen ingrediënt gevonden voor deze barcode")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Fout bij zoeken ingrediënt: $e")),
          );
        }
      }
    }
  }

  Future<void> _searchIngredientByName(int index) async {
    final ingredient = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _IngredientSearchDialog(),
    );

    if (ingredient != null) {
      setState(() {
        _ingredients[index]['ingredient'] = ingredient;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Menu Item toevoegen"),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe selection
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
                        label: Text(_selectedRecipe == null
                            ? "Kies recept"
                            : "Gekozen: ${_selectedRecipe!['name']}"),
                        onPressed: _pickRecipe,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Basic info
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

                    // Category selection with inline creation
                    const Text(
                      "Categorie",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    if (_showNewCategoryField) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _newCategoryController,
                              decoration: const InputDecoration(
                                labelText: "Nieuwe categorie naam",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: _createNewCategory,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _showNewCategoryField = false;
                                _newCategoryController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ] else ...[
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text("Selecteer categorie"),
                        items: [
                          ..._categories
                              .map((category) => DropdownMenuItem<int>(
                                    value: category['id'],
                                    child: Text(category['name'] ?? ''),
                                  )),
                          const DropdownMenuItem<int>(
                            value: -1,
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 16),
                                SizedBox(width: 8),
                                Text("Nieuwe categorie aanmaken"),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == -1) {
                            setState(() {
                              _showNewCategoryField = true;
                            });
                          } else {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Ingredients section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Ingrediënten",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Ingrediënt toevoegen"),
                          onPressed: _addIngredient,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ..._ingredients.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ingredient = entry.value;
                      return _buildIngredientCard(index, ingredient);
                    }),

                    const SizedBox(height: 16),

                    // Available toggle
                    SwitchListTile(
                      title: const Text("Beschikbaar"),
                      value: _available,
                      onChanged: (v) => setState(() => _available = v),
                    ),
                    const SizedBox(height: 24),

                    // Save buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text("Opslaan"),
                            onPressed: () => _saveMenuItem(saveAndNext: false),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save_alt),
                            label: const Text("Opslaan en volgende"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                            ),
                            onPressed: () => _saveMenuItem(saveAndNext: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIngredientCard(int index, Map<String, dynamic> ingredient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ingredient['ingredient']?['name'] ??
                        'Geen ingrediënt geselecteerd',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => _searchIngredientByBarcode(index),
                  tooltip: "Scan barcode",
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchIngredientByName(index),
                  tooltip: "Zoek op naam",
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeIngredient(index),
                ),
              ],
            ),
            if (ingredient['ingredient'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: ingredient['quantity'].toString(),
                      decoration: const InputDecoration(
                        labelText: "Hoeveelheid",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        ingredient['quantity'] = double.tryParse(value) ?? 1.0;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: ingredient['unit'],
                      decoration: const InputDecoration(
                        labelText: "Eenheid",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'gram', child: Text('gram')),
                        DropdownMenuItem(value: 'kilogram', child: Text('kg')),
                        DropdownMenuItem(value: 'liter', child: Text('liter')),
                        DropdownMenuItem(
                            value: 'milliliter', child: Text('ml')),
                        DropdownMenuItem(value: 'stuks', child: Text('stuks')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ingredient['unit'] = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: ingredient['notes'],
                decoration: const InputDecoration(
                  labelText: "Opmerkingen (optioneel)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  ingredient['notes'] = value;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -------------------
// RECIPE PICKER DIALOG
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

// -------------------
// INGREDIENT SEARCH DIALOG
// -------------------
class _IngredientSearchDialog extends ConsumerStatefulWidget {
  const _IngredientSearchDialog();

  @override
  ConsumerState<_IngredientSearchDialog> createState() =>
      _IngredientSearchDialogState();
}

class _IngredientSearchDialogState
    extends ConsumerState<_IngredientSearchDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _ingredients = [];
  bool _loading = false;

  Future<void> _searchIngredients(String query) async {
    if (query.length < 2) {
      setState(() {
        _ingredients = [];
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await _apiService.searchIngredients(query);
      setState(() {
        _ingredients =
            List<Map<String, dynamic>>.from(response['ingredients'] ?? []);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij zoeken ingrediënten: $e")),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _createNewIngredient() async {
    final newIngredient = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CreateIngredientDialog(),
    );

    if (newIngredient != null) {
      Navigator.pop(context, newIngredient);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Zoek ingrediënt"),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Typ ingrediënt naam...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchIngredients,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Nieuw ingrediënt aanmaken"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _createNewIngredient,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _ingredients.isEmpty && _searchController.text.length >= 2
                      ? const Center(
                          child: Text(
                            "Geen ingrediënten gevonden.\nMaak een nieuw ingrediënt aan.",
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _ingredients.length,
                          itemBuilder: (context, i) {
                            final ingredient = _ingredients[i];
                            return ListTile(
                              leading: const Icon(Icons.eco),
                              title: Text(ingredient['name'] ?? ''),
                              subtitle: Text(ingredient['description'] ??
                                  'Geen beschrijving'),
                              trailing: ingredient['verified'] == true
                                  ? const Icon(Icons.verified,
                                      color: Colors.green)
                                  : null,
                              onTap: () => Navigator.pop(context, ingredient),
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

// -------------------
// CREATE INGREDIENT DIALOG
// -------------------
class _CreateIngredientDialog extends ConsumerStatefulWidget {
  const _CreateIngredientDialog();

  @override
  ConsumerState<_CreateIngredientDialog> createState() =>
      _CreateIngredientDialogState();
}

class _CreateIngredientDialogState
    extends ConsumerState<_CreateIngredientDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _energyController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();

  bool _isLoading = false;
  List<String> _selectedAllergens = [];

  final List<String> _availableAllergens = [
    'gluten',
    'melk',
    'ei',
    'vis',
    'schaaldieren',
    'noten',
    "pinda's",
    'soja',
    'selderij',
    'mosterd',
    'sesam',
    'sulfiet',
    'lupine',
    'weekdieren'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _energyController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _createIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ingredientData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'code': _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        'energy_kcal': _energyController.text.trim().isEmpty
            ? null
            : double.tryParse(_energyController.text.trim()),
        'protein_g': _proteinController.text.trim().isEmpty
            ? null
            : double.tryParse(_proteinController.text.trim()),
        'fat_g': _fatController.text.trim().isEmpty
            ? null
            : double.tryParse(_fatController.text.trim()),
        'carbs_g': _carbsController.text.trim().isEmpty
            ? null
            : double.tryParse(_carbsController.text.trim()),
        'allergens': _selectedAllergens,
        'source': 'Manual',
        'is_verified': false,
      };

      final response = await _apiService.createIngredient(ingredientData);
      final newIngredient = response['ingredient'];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ingrediënt succesvol aangemaakt")),
        );
        Navigator.pop(context, newIngredient);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout bij aanmaken ingrediënt: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nieuw ingrediënt aanmaken"),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Naam *",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Naam is verplicht";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Beschrijving",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: "Barcode (13 cijfers)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (value.trim().length != 13 ||
                                !RegExp(r'^\d+$').hasMatch(value.trim())) {
                              return "Barcode moet 13 cijfers zijn";
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Voedingswaarden (per 100g)",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _energyController,
                              decoration: const InputDecoration(
                                labelText: "Energie (kcal)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _proteinController,
                              decoration: const InputDecoration(
                                labelText: "Eiwit (g)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fatController,
                              decoration: const InputDecoration(
                                labelText: "Vet (g)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _carbsController,
                              decoration: const InputDecoration(
                                labelText: "Koolhydraten (g)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Allergenen",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _availableAllergens.map((allergen) {
                          final isSelected =
                              _selectedAllergens.contains(allergen);
                          return FilterChip(
                            label: Text(allergen),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAllergens.add(allergen);
                                } else {
                                  _selectedAllergens.remove(allergen);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuleren"),
        ),
        ElevatedButton(
          onPressed: _createIngredient,
          child: const Text("Aanmaken"),
        ),
      ],
    );
  }
}

// -------------------
// BARCODE SCANNER DIALOG
// -------------------
class _BarcodeScannerDialog extends StatefulWidget {
  const _BarcodeScannerDialog();

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Scan barcode"),
      content: SizedBox(
        width: 300,
        height: 300,
        child: MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final barcode = barcodes.first.rawValue;
              if (barcode != null) {
                Navigator.pop(context, barcode);
              }
            }
          },
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
