import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class IngredientsPage extends ConsumerStatefulWidget {
  const IngredientsPage({super.key});

  @override
  ConsumerState<IngredientsPage> createState() => _IngredientsPageState();
}

class _IngredientsPageState extends ConsumerState<IngredientsPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  bool _isLoading = true;
  bool _isScanning = false;
  List<Map<String, dynamic>> _ingredients = [];
  List<Map<String, dynamic>> _filteredIngredients = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  String _sortBy = 'name'; // name, created_at, calories, protein
  bool _sortAscending = true;
  String _filterBy = 'all'; // all, verified, unverified, custom

  final Map<String, String> _sortOptions = {
    'name': 'Naam',
    'created_at': 'Datum toegevoegd',
    'calories': 'Calorieën',
    'protein': 'Eiwitten',
    'carbs': 'Koolhydraten',
    'fat': 'Vetten',
  };

  final Map<String, String> _filterOptions = {
    'all': 'Alle ingrediënten',
    'verified': 'Geverifieerd',
    'unverified': 'Niet geverifieerd',
    'custom': 'Aangepast',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final ingredientsResponse = await _apiService.getIngredients();

      final ingredients = List<Map<String, dynamic>>.from(
          ingredientsResponse['ingredients'] ?? []);

      setState(() {
        _ingredients = ingredients;
        _isLoading = false;
      });

      _filterIngredients();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden ingrediënten: $e')),
        );
      }
    }
  }

  void _filterIngredients() {
    List<Map<String, dynamic>> filtered = List.from(_ingredients);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ingredient) {
        final name = (ingredient['name'] ?? '').toLowerCase();
        final brand = (ingredient['brand'] ?? '').toLowerCase();
        final ean = (ingredient['ean_code'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            brand.contains(query) ||
            ean.contains(query);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((ingredient) {
        return ingredient['category_id'] == _selectedCategory;
      }).toList();
    }

    // Apply verification filter
    if (_filterBy != 'all') {
      filtered = filtered.where((ingredient) {
        switch (_filterBy) {
          case 'verified':
            return ingredient['is_verified'] == true;
          case 'unverified':
            return ingredient['is_verified'] != true;
          case 'custom':
            return ingredient['is_custom'] == true;
          default:
            return true;
        }
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      dynamic aValue = a[_sortBy];
      dynamic bValue = b[_sortBy];

      if (['calories', 'protein', 'carbs', 'fat'].contains(_sortBy)) {
        aValue = (aValue ?? 0).toDouble();
        bValue = (bValue ?? 0).toDouble();
      } else if (_sortBy == 'created_at') {
        aValue = DateTime.tryParse(aValue ?? '') ?? DateTime.now();
        bValue = DateTime.tryParse(bValue ?? '') ?? DateTime.now();
      } else {
        aValue = (aValue ?? '').toString().toLowerCase();
        bValue = (bValue ?? '').toString().toLowerCase();
      }

      int comparison = Comparable.compare(aValue, bValue);
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredIngredients = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ingrediënten Database'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _startBarcodeScanning(),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _showImportDialog();
                  break;
                case 'export':
                  _exportIngredients();
                  break;
                case 'sync':
                  _syncWithDatabase();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Importeren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exporteren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'sync',
                child: ListTile(
                  leading: Icon(Icons.sync),
                  title: Text('Synchroniseren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.onPrimary,
            labelColor: AppColors.onPrimary,
            unselectedLabelColor:
                AppColors.withAlphaFraction(AppColors.onPrimary, 0.7),
            isScrollable: true,
            tabs: const [
              Tab(text: 'Alle Ingrediënten'),
              Tab(text: 'Barcode Scanner'),
              Tab(text: 'Nutritional Data'),
              Tab(text: 'Categorieën'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildIngredientsTab(),
                _buildBarcodeScannerTab(),
                _buildNutritionalDataTab(),
                _buildCategoriesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIngredientDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nieuw Ingrediënt'),
      ),
    );
  }

  Widget _buildIngredientsTab() {
    return Column(
      children: [
        // Search and filter bar
        _buildSearchAndFilter(),

        // Ingredients list
        Expanded(
          child: _filteredIngredients.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredIngredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _filteredIngredients[index];
                      return _buildIngredientCard(ingredient);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.withAlphaFraction(AppColors.black, 0.05),
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
              hintText: 'Zoek ingrediënten, merken, EAN codes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _filterIngredients();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => _startBarcodeScanning(),
                  ),
                ],
              ),
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterIngredients();
            },
          ),

          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Verification filter
                ..._filterOptions.entries.map((entry) {
                  final isSelected = _filterBy == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filterBy = selected ? entry.key : 'all';
                        });
                        _filterIngredients();
                      },
                      backgroundColor: AppColors.background,
                      selectedColor:
                          AppColors.withAlphaFraction(AppColors.primary, 0.2),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                }).toList(),

                const SizedBox(width: 8),

                // Category filters
                ..._categories.map((category) {
                  final isSelected = _selectedCategory == category['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category['name'] ?? ''),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category['id'] : null;
                        });
                        _filterIngredients();
                      },
                      backgroundColor: AppColors.background,
                      selectedColor:
                          AppColors.withAlphaFraction(AppColors.primary, 0.2),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(Map<String, dynamic> ingredient) {
    final isVerified = ingredient['is_verified'] == true;
    final isCustom = ingredient['is_custom'] == true;
    final calories = ingredient['calories_per_100g'] ?? 0;
    final protein = ingredient['protein_per_100g'] ?? 0;
    final carbs = ingredient['carbs_per_100g'] ?? 0;
    final fat = ingredient['fat_per_100g'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showIngredientDetails(ingredient),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and badges
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredient['name'] ?? '',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (ingredient['brand'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            ingredient['brand'],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.withAlphaFraction(Colors.green, 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Geverifieerd',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      if (isCustom) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.withAlphaFraction(Colors.blue, 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Aangepast',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleIngredientAction(value, ingredient),
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
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Dupliceren'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (!isVerified)
                        const PopupMenuItem(
                          value: 'verify',
                          child: ListTile(
                            leading: Icon(Icons.verified, color: Colors.green),
                            title: Text('Verifiëren'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Verwijderen',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // EAN code if available
              if (ingredient['ean_code'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.qr_code,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'EAN: ${ingredient['ean_code']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Nutritional information
              Row(
                children: [
                  Expanded(
                    child: _buildNutritionChip(
                      label: 'Calorieën',
                      value: '${calories.toStringAsFixed(0)}',
                      unit: 'kcal',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNutritionChip(
                      label: 'Eiwitten',
                      value: '${protein.toStringAsFixed(1)}',
                      unit: 'g',
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNutritionChip(
                      label: 'Koolhydraten',
                      value: '${carbs.toStringAsFixed(1)}',
                      unit: 'g',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNutritionChip(
                      label: 'Vetten',
                      value: '${fat.toStringAsFixed(1)}',
                      unit: 'g',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Additional info
              if (ingredient['allergens'] != null &&
                  ingredient['allergens'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      (ingredient['allergens'] as List).map<Widget>((allergen) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.withAlphaFraction(
                            AppColors.calorieMarginVeryHigh, 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.withAlphaFraction(
                                AppColors.calorieMarginVeryHigh, 0.3)),
                      ),
                      child: Text(
                        allergen,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionChip({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.withAlphaFraction(color, 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$value$unit',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeScannerTab() {
    return Column(
      children: [
        // Scanner instructions
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.withAlphaFraction(AppColors.primary, 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.withAlphaFraction(AppColors.primary, 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Scan een barcode om ingrediënt informatie op te halen uit de database',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ),
            ],
          ),
        ),

        // Scanner button
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.withAlphaFraction(AppColors.primary, 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Barcode Scanner',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan een product barcode om ingrediënt informatie op te halen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : () => _startBarcodeScanning(),
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_scanner),
                  label: Text(_isScanning ? 'Scannen...' : 'Start Scanner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionalDataTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nutritional Data Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gedetailleerde voedingswaarde analytics worden binnenkort toegevoegd',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingrediënt Categorieën',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Categorie beheer wordt binnenkort toegevoegd',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              Icons.inventory_2,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ||
                      _selectedCategory != null ||
                      _filterBy != 'all'
                  ? 'Geen ingrediënten gevonden'
                  : 'Nog geen ingrediënten',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ||
                      _selectedCategory != null ||
                      _filterBy != 'all'
                  ? 'Probeer een andere zoekopdracht of filter'
                  : 'Voeg je eerste ingrediënt toe of scan een barcode',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty &&
                _selectedCategory == null &&
                _filterBy == 'all') ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startBarcodeScanning(),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Barcode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddIngredientDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Handmatig Toevoegen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sorteren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._sortOptions.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  _filterIngredients();
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const Divider(),
            SwitchListTile(
              title: const Text('Oplopend'),
              subtitle:
                  Text(_sortAscending ? 'A-Z, Laag-Hoog' : 'Z-A, Hoog-Laag'),
              value: _sortAscending,
              onChanged: (value) {
                setState(() {
                  _sortAscending = value;
                });
                _filterIngredients();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _startBarcodeScanning() {
    setState(() => _isScanning = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Scan Barcode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _isScanning = false);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Scanner
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final barcode = barcodes.first;
                    if (barcode.rawValue != null) {
                      setState(() => _isScanning = false);
                      Navigator.pop(context);
                      _handleBarcodeScanned(barcode.rawValue!);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      setState(() => _isScanning = false);
    });
  }

  Future<void> _handleBarcodeScanned(String barcode) async {
    try {
      final response = await _apiService.lookupIngredientByBarcode(barcode);

      if (response['ingredient'] != null) {
        // Ingredient found in database
        _showIngredientDetails(response['ingredient']);
      } else {
        // Ingredient not found, offer to add it
        _showAddIngredientFromBarcodeDialog(barcode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opzoeken barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showIngredientDetails(Map<String, dynamic> ingredient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ingredient['name'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ingredient['brand'] != null) ...[
                Text('Merk: ${ingredient['brand']}'),
                const SizedBox(height: 8),
              ],
              if (ingredient['ean_code'] != null) ...[
                Text('EAN: ${ingredient['ean_code']}'),
                const SizedBox(height: 8),
              ],
              const Text('Voedingswaarden per 100g:'),
              const SizedBox(height: 8),
              Text('Calorieën: ${ingredient['calories_per_100g'] ?? 0} kcal'),
              Text('Eiwitten: ${ingredient['protein_per_100g'] ?? 0}g'),
              Text('Koolhydraten: ${ingredient['carbs_per_100g'] ?? 0}g'),
              Text('Vetten: ${ingredient['fat_per_100g'] ?? 0}g'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleIngredientAction('edit', ingredient);
            },
            child: const Text('Bewerken'),
          ),
        ],
      ),
    );
  }

  void _showAddIngredientFromBarcodeDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingrediënt Niet Gevonden'),
        content: Text(
            'Barcode $barcode is niet gevonden in de database. Wil je dit ingrediënt handmatig toevoegen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddIngredientDialog(eanCode: barcode);
            },
            child: const Text('Toevoegen'),
          ),
        ],
      ),
    );
  }

  void _showAddIngredientDialog({String? eanCode}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuw Ingrediënt'),
        content: Text(eanCode != null
            ? 'Ingrediënt toevoegen met EAN code: $eanCode'
            : 'Ingrediënt toevoegen functionaliteit wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleIngredientAction(String action, Map<String, dynamic> ingredient) {
    switch (action) {
      case 'edit':
        _editIngredient(ingredient);
        break;
      case 'duplicate':
        _duplicateIngredient(ingredient);
        break;
      case 'verify':
        _verifyIngredient(ingredient);
        break;
      case 'delete':
        _deleteIngredient(ingredient);
        break;
    }
  }

  void _editIngredient(Map<String, dynamic> ingredient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingrediënt Bewerken'),
        content: Text(
            'Bewerken van "${ingredient['name']}" wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _duplicateIngredient(Map<String, dynamic> ingredient) async {
    try {
      await _apiService.duplicateIngredient(ingredient['id']);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ingrediënt "${ingredient['name']}" gedupliceerd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij dupliceren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verifyIngredient(Map<String, dynamic> ingredient) async {
    try {
      await _apiService.verifyIngredient(ingredient['id']);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ingrediënt "${ingredient['name']}" geverifieerd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij verifiëren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteIngredient(Map<String, dynamic> ingredient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingrediënt Verwijderen'),
        content: Text(
            'Weet je zeker dat je "${ingredient['name']}" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteIngredient(ingredient['id']);
                await _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Ingrediënt "${ingredient['name']}" verwijderd'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fout bij verwijderen: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingrediënten Importeren'),
        content:
            const Text('Import functionaliteit wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exportIngredients() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionaliteit wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _syncWithDatabase() async {
    try {
      await _apiService.syncIngredients();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database gesynchroniseerd'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij synchroniseren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
