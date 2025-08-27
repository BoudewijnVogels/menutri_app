import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class MenuManagementPage extends ConsumerStatefulWidget {
  const MenuManagementPage({super.key});

  @override
  ConsumerState<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _restaurants = [];
  Map<String, dynamic>? _selectedRestaurant;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _filteredMenuItems = [];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _searchController.addListener(_filterMenuItems);
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
      final restaurantsResponse = await _apiService.getRestaurants();
      final restaurants = List<Map<String, dynamic>>.from(
          restaurantsResponse['restaurants'] ?? []);

      setState(() {
        _restaurants = restaurants;
        if (restaurants.isNotEmpty) {
          _selectedRestaurant = restaurants.first;
        }
        _isLoading = false;
      });

      if (_selectedRestaurant != null) {
        await _loadMenuData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden data: $e')),
        );
      }
    }
  }

  Future<void> _loadMenuData() async {
    if (_selectedRestaurant == null) return;

    try {
      // Haal het restaurantId veilig als int op
      final int restaurantId = (_selectedRestaurant!['id'] as num).toInt();

      // Getypte Future.wait voorkomt unnecessary_cast warnings
      final results = await Future.wait<Map<String, dynamic>>([
        _apiService.getCategories(menuId: restaurantId),
        _apiService.getMenuItems(restaurantId: restaurantId),
      ]);

      final catsResp = results[0];
      final itemsResp = results[1];

      setState(() {
        _categories = List<Map<String, dynamic>>.from(
          catsResp['categories'] ?? const [],
        );

        // Backend kan "items" of "menu_items" teruggeven
        _menuItems = List<Map<String, dynamic>>.from(
          (itemsResp['items'] ?? itemsResp['menu_items'] ?? const []),
        );

        _filteredMenuItems = _menuItems;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden menu data: $e')),
        );
      }
    }
  }

  void _filterMenuItems() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredMenuItems = _menuItems.where((item) {
        final matchesSearch =
            item['name']?.toLowerCase().contains(query) ?? false;
        final matchesCategory = _selectedCategory == 'all' ||
            item['category_id'].toString() == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu Beheer'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => context.push('/cateraar/qr-generator'),
          ),
        ],
        bottom: _restaurants.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.onPrimary,
                  labelColor: AppColors.onPrimary,
                  unselectedLabelColor:
                      AppColors.onPrimary.withValues(alpha: 179),
                  tabs: const [
                    Tab(text: 'Menu Items'),
                    Tab(text: 'Categorieën'),
                    Tab(text: 'Recepten'),
                  ],
                ),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _restaurants.isEmpty
              ? _buildNoRestaurantsState()
              : Column(
                  children: [
                    // Restaurant selector
                    _buildRestaurantSelector(),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMenuItemsTab(),
                          _buildCategoriesTab(),
                          _buildRecipesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _restaurants.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddItemDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: Text(_getAddButtonLabel()),
            )
          : null,
    );
  }

  Widget _buildNoRestaurantsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Geen Restaurants',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg eerst een restaurant toe om menu\'s te kunnen beheren',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/cateraar/restaurants/add'),
              icon: const Icon(Icons.add),
              label: const Text('Restaurant Toevoegen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedRestaurant,
              decoration: const InputDecoration(
                labelText: 'Selecteer Restaurant',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _restaurants.map((restaurant) {
                return DropdownMenuItem(
                  value: restaurant,
                  child: Text(restaurant['name'] ?? ''),
                );
              }).toList(),
              onChanged: (restaurant) {
                setState(() {
                  _selectedRestaurant = restaurant;
                });
                if (restaurant != null) {
                  _loadMenuData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    return Column(
      children: [
        // Search and filter
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Zoek menu items...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Alle'),
                      selected: _selectedCategory == 'all',
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = 'all';
                        });
                        _filterMenuItems();
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._categories.map((category) {
                      final isSelected =
                          _selectedCategory == category['id'].toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category['name'] ?? ''),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory =
                                  selected ? category['id'].toString() : 'all';
                            });
                            _filterMenuItems();
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Menu items list
        Expanded(
          child: _filteredMenuItems.isEmpty
              ? _buildEmptyMenuItemsState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredMenuItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredMenuItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMenuItemCard(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyMenuItemsState() {
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
              'Geen Menu Items',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg je eerste menu item toe',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    final price = item['price']?.toDouble() ?? 0.0;
    final calories = item['calories']?.toInt() ?? 0;
    final isAvailable = item['is_available'] ?? true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _editMenuItem(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Item image or placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 26),
                  borderRadius: BorderRadius.circular(8),
                  image: item['image_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(item['image_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item['image_url'] == null
                    ? Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primary,
                        size: 30,
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '€${price.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (item['description'] != null)
                      Text(
                        item['description'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (calories > 0) ...[
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$calories kcal',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.green.withValues(alpha: 26)
                                : Colors.red.withValues(alpha: 26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAvailable ? 'Beschikbaar' : 'Niet beschikbaar',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      isAvailable ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          onSelected: (value) =>
                              _handleMenuItemAction(value, item),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Bewerken'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: isAvailable ? 'disable' : 'enable',
                              child: ListTile(
                                leading: Icon(
                                  isAvailable
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                title: Text(isAvailable
                                    ? 'Uitschakelen'
                                    : 'Inschakelen'),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Expanded(
          child: _categories.isEmpty
              ? _buildEmptyCategoriesState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCategoryCard(category),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyCategoriesState() {
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
              'Geen Categorieën',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg categorieën toe om je menu te organiseren',
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

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final itemCount = _menuItems
        .where((item) => item['category_id'] == category['id'])
        .length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.category,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          category['name'] ?? '',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text('$itemCount items'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCategoryAction(value, category),
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
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Verwijderen', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _editCategory(category),
      ),
    );
  }

  Widget _buildRecipesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Recepten Beheer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recepten functionaliteit wordt binnenkort toegevoegd',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/cateraar/recipes'),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Naar Recepten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAddButtonLabel() {
    switch (_tabController.index) {
      case 0:
        return 'Menu Item';
      case 1:
        return 'Categorie';
      case 2:
        return 'Recept';
      default:
        return 'Toevoegen';
    }
  }

  void _showAddItemDialog() {
    switch (_tabController.index) {
      case 0:
        _addMenuItem();
        break;
      case 1:
        _addCategory();
        break;
      case 2:
        _addRecipe();
        break;
    }
  }

  void _addMenuItem() {
    context.push(
        '/cateraar/menu-items/add?restaurant_id=${_selectedRestaurant!['id']}');
  }

  void _editMenuItem(Map<String, dynamic> item) {
    context.push('/cateraar/menu-items/${item['id']}/edit');
  }

  void _addCategory() {
    context.push(
        '/cateraar/categories/add?restaurant_id=${_selectedRestaurant!['id']}');
  }

  void _editCategory(Map<String, dynamic> category) {
    context.push('/cateraar/categories/${category['id']}/edit');
  }

  void _addRecipe() {
    context.push('/cateraar/recipes/add');
  }

  void _handleMenuItemAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'edit':
        _editMenuItem(item);
        break;
      case 'enable':
      case 'disable':
        _toggleMenuItemAvailability(item);
        break;
      case 'duplicate':
        _duplicateMenuItem(item);
        break;
      case 'delete':
        _showDeleteMenuItemConfirmation(item);
        break;
    }
  }

  void _handleCategoryAction(String action, Map<String, dynamic> category) {
    switch (action) {
      case 'edit':
        _editCategory(category);
        break;
      case 'delete':
        _showDeleteCategoryConfirmation(category);
        break;
    }
  }

  Future<void> _toggleMenuItemAvailability(Map<String, dynamic> item) async {
    final newAvailability = !(item['is_available'] ?? true);

    try {
      await _apiService.updateMenuItem(
        item['id'],
        {'is_available': newAvailability},
      );

      setState(() {
        item['is_available'] = newAvailability;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Menu item ${newAvailability ? 'ingeschakeld' : 'uitgeschakeld'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij wijzigen beschikbaarheid: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _duplicateMenuItem(Map<String, dynamic> item) async {
    try {
      final newItem = Map<String, dynamic>.from(item);
      newItem.remove('id');
      newItem['name'] = '${item['name']} (Kopie)';

      await _apiService.createMenuItem(newItem);
      await _loadMenuData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu item gedupliceerd'),
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

  void _showDeleteMenuItemConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menu Item Verwijderen'),
        content: Text(
          'Weet je zeker dat je "${item['name']}" wilt verwijderen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMenuItem(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryConfirmation(Map<String, dynamic> category) {
    final itemCount = _menuItems
        .where((item) => item['category_id'] == category['id'])
        .length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Categorie Verwijderen'),
        content: Text(
          itemCount > 0
              ? 'Deze categorie bevat $itemCount menu items. '
                  'Weet je zeker dat je "${category['name']}" wilt verwijderen?'
              : 'Weet je zeker dat je "${category['name']}" wilt verwijderen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenuItem(Map<String, dynamic> item) async {
    try {
      await _apiService.deleteMenuItem(item['id']);
      await _loadMenuData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu item verwijderd'),
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
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    try {
      await _apiService.deleteCategory(category['id']);
      await _loadMenuData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categorie verwijderd'),
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
  }
}
