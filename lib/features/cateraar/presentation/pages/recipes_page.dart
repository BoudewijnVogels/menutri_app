import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _filteredRecipes = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  String _sortBy = 'name'; // name, created_at, prep_time, difficulty
  bool _sortAscending = true;

  final Map<String, String> _sortOptions = {
    'name': 'Naam',
    'created_at': 'Datum',
    'prep_time': 'Bereidingstijd',
    'difficulty': 'Moeilijkheidsgraad',
  };

  final Map<String, String> _difficultyLabels = {
    'easy': 'Makkelijk',
    'medium': 'Gemiddeld',
    'hard': 'Moeilijk',
  };

  final Map<String, Color> _difficultyColors = {
    'easy': Colors.green,
    'medium': Colors.orange,
    'hard': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final recipesResponse = await _apiService.getRecipes();
      final categoriesResponse = await _apiService.getCategories();
      
      final recipes = List<Map<String, dynamic>>.from(
        recipesResponse['recipes'] ?? []
      );
      final categories = List<Map<String, dynamic>>.from(
        categoriesResponse['categories'] ?? []
      );
      
      setState(() {
        _recipes = recipes;
        _categories = categories;
        _isLoading = false;
      });
      
      _filterRecipes();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden recepten: $e')),
        );
      }
    }
  }

  void _filterRecipes() {
    List<Map<String, dynamic>> filtered = List.from(_recipes);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recipe) {
        final name = (recipe['name'] ?? '').toLowerCase();
        final description = (recipe['description'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((recipe) {
        return recipe['category_id'] == _selectedCategory;
      }).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      dynamic aValue = a[_sortBy];
      dynamic bValue = b[_sortBy];
      
      if (_sortBy == 'prep_time') {
        aValue = aValue ?? 0;
        bValue = bValue ?? 0;
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
      _filteredRecipes = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recepten'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
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
                  _exportRecipes();
                  break;
                case 'bulk_edit':
                  _showBulkEditDialog();
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
                value: 'bulk_edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Bulk Bewerken'),
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
            unselectedLabelColor: AppColors.onPrimary.withOpacity(0.7),
            tabs: const [
              Tab(text: 'Alle Recepten'),
              Tab(text: 'Categorieën'),
              Tab(text: 'Ingrediënten'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecipesTab(),
                _buildCategoriesTab(),
                _buildIngredientsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecipeDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nieuw Recept'),
      ),
    );
  }

  Widget _buildRecipesTab() {
    return Column(
      children: [
        // Search and filter bar
        _buildSearchAndFilter(),
        
        // Recipes list
        Expanded(
          child: _filteredRecipes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _filteredRecipes[index];
                      return _buildRecipeCard(recipe);
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
            color: Colors.black.withOpacity(0.05),
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
              hintText: 'Zoek recepten...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _filterRecipes();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterRecipes();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Alle'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                    });
                    _filterRecipes();
                  },
                  backgroundColor: AppColors.background,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
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
                        _filterRecipes();
                      },
                      backgroundColor: AppColors.background,
                      selectedColor: AppColors.primary.withOpacity(0.2),
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

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final difficulty = recipe['difficulty'] ?? 'easy';
    final prepTime = recipe['prep_time'] ?? 0;
    final servings = recipe['servings'] ?? 1;
    final calories = recipe['calories_per_serving'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRecipeDetails(recipe),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: recipe['image_url'] != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        recipe['image_url'],
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildRecipeImagePlaceholder();
                        },
                      ),
                    )
                  : _buildRecipeImagePlaceholder(),
            ),
            
            // Recipe info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and difficulty
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe['name'] ?? '',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _difficultyColors[difficulty]?.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _difficultyLabels[difficulty] ?? difficulty,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _difficultyColors[difficulty],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  if (recipe['description'] != null) ...[
                    Text(
                      recipe['description'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Stats
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.schedule,
                        label: '${prepTime}min',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        icon: Icons.people,
                        label: '${servings}p',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        icon: Icons.local_fire_department,
                        label: '${calories}kcal',
                        color: Colors.orange,
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleRecipeAction(value, recipe),
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
                          const PopupMenuItem(
                            value: 'share',
                            child: ListTile(
                              leading: Icon(Icons.share),
                              title: Text('Delen'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Verwijderen', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 48,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Geen afbeelding',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
              Icons.restaurant_menu,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? 'Geen recepten gevonden'
                  : 'Nog geen recepten',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? 'Probeer een andere zoekopdracht of filter'
                  : 'Voeg je eerste recept toe om te beginnen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && _selectedCategory == null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddRecipeDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Eerste Recept Toevoegen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ],
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
              'Recept Categorieën',
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

  Widget _buildIngredientsTab() {
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
              'Ingrediënten Overzicht',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingrediënten overzicht wordt binnenkort toegevoegd',
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
                  _filterRecipes();
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const Divider(),
            SwitchListTile(
              title: const Text('Oplopend'),
              subtitle: Text(_sortAscending ? 'A-Z, Laag-Hoog' : 'Z-A, Hoog-Laag'),
              value: _sortAscending,
              onChanged: (value) {
                setState(() {
                  _sortAscending = value;
                });
                _filterRecipes();
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

  void _showAddRecipeDialog() {
    // In a real app, this would navigate to a full recipe creation form
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuw Recept'),
        content: const Text('Recept toevoegen functionaliteit wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    // In a real app, this would navigate to a detailed recipe view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe['name'] ?? ''),
        content: Text(recipe['description'] ?? 'Geen beschrijving beschikbaar'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _handleRecipeAction(String action, Map<String, dynamic> recipe) {
    switch (action) {
      case 'edit':
        _editRecipe(recipe);
        break;
      case 'duplicate':
        _duplicateRecipe(recipe);
        break;
      case 'share':
        _shareRecipe(recipe);
        break;
      case 'delete':
        _deleteRecipe(recipe);
        break;
    }
  }

  void _editRecipe(Map<String, dynamic> recipe) {
    // Navigate to edit form
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recept Bewerken'),
        content: Text('Bewerken van "${recipe['name']}" wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _duplicateRecipe(Map<String, dynamic> recipe) async {
    try {
      await _apiService.duplicateRecipe(recipe['id']);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recept "${recipe['name']}" gedupliceerd'),
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

  void _shareRecipe(Map<String, dynamic> recipe) {
    // Share recipe functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delen van "${recipe['name']}" wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _deleteRecipe(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recept Verwijderen'),
        content: Text('Weet je zeker dat je "${recipe['name']}" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteRecipe(recipe['id']);
                await _loadData();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recept "${recipe['name']}" verwijderd'),
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
        title: const Text('Recepten Importeren'),
        content: const Text('Import functionaliteit wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exportRecipes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionaliteit wordt binnenkort toegevoegd'),
      ),
    );
  }

  void _showBulkEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Bewerken'),
        content: const Text('Bulk bewerken functionaliteit wordt binnenkort toegevoegd'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

