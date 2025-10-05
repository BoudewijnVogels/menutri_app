import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class MenuManagementPage extends ConsumerStatefulWidget {
  final int menuId;

  const MenuManagementPage({super.key, required this.menuId});

  @override
  ConsumerState<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic>? _menu;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _filteredMenuItems = [];
  final String _selectedCategory = 'all';

  final List<String> _statusOptions = ['concept', 'actief', 'inactief'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMenuData();
    _searchController.addListener(_filterMenuItems);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuData() async {
    setState(() => _isLoading = true);

    try {
      final menuResp = await _apiService.getMenu(widget.menuId);
      final catsResp = await _apiService.getCategories(menuId: widget.menuId);
      final itemsResp = await _apiService.getMenuItems(menuId: widget.menuId);

      setState(() {
        _menu = menuResp;
        _categories =
            List<Map<String, dynamic>>.from(catsResp['categories'] ?? const []);
        _menuItems = List<Map<String, dynamic>>.from(
          (itemsResp['items'] ?? itemsResp['menu_items'] ?? const []),
        );
        _filteredMenuItems = _menuItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden menukaart: $e')),
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

  Future<void> _saveMenu() async {
    if (_menu == null) return;
    try {
      await _apiService.updateMenu(widget.menuId, {
        'name': _menu!['name'],
        'status': _menu!['status'],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menukaart opgeslagen'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadMenuData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opslaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_menu?['name'] ?? 'Menukaart'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => context.push('/cateraar/qr-generator'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.onPrimary,
            labelColor: AppColors.onPrimary,
            unselectedLabelColor: AppColors.onPrimary.withValues(alpha: 179),
            tabs: const [
              Tab(text: 'Menu Items'),
              Tab(text: 'Categorieën'),
              Tab(text: 'Recepten'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMenuHeader(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(_getAddButtonLabel()),
      ),
    );
  }

  Widget _buildMenuHeader() {
    final currentStatus = _menu?['status'] ?? 'concept';

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
          // Inline bewerken van naam
          Expanded(
            child: TextFormField(
              initialValue: _menu?['name'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Naam menukaart',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _menu?['name'] = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),

          // Status dropdown
          DropdownButton<String>(
            value: _statusOptions.contains(currentStatus)
                ? currentStatus
                : 'concept',
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status[0].toUpperCase() + status.substring(1)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _menu?['status'] = value;
                });
              }
            },
          ),
          const SizedBox(width: 16),

          // Opslaan-knop
          ElevatedButton(
            onPressed: _saveMenu,
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    final lists = [
      DragAndDropList(
        header: _buildCategoryHeader('Alle items'),
        children: _filteredMenuItems.map((item) {
          return DragAndDropItem(
            child: _buildMenuItemCard(item),
          );
        }).toList(),
      ),
      ..._categories.map((category) {
        final categoryItems = _filteredMenuItems
            .where((item) => item['category_id'] == category['id'])
            .toList();

        return DragAndDropList(
          header: _buildCategoryHeader(category['name'] ?? ''),
          children: categoryItems.map((item) {
            return DragAndDropItem(
              child: _buildMenuItemCard(item),
            );
          }).toList(),
        );
      }),
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DragAndDropLists(
        children: lists,
        onItemReorder: _onItemReorder,
        onListReorder: (oldListIndex, newListIndex) {
          // categorieën sorteren kan later
        },
        listPadding: const EdgeInsets.symmetric(vertical: 12),
        listDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 10),
              blurRadius: 3,
            )
          ],
        ),
        listInnerDecoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        itemDecorationWhileDragging: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 50),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      ),
    );
  }

  void _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) async {
    setState(() {
      final movedItem = _filteredMenuItems.removeAt(oldItemIndex);
      _filteredMenuItems.insert(newItemIndex, movedItem);
    });

    try {
      final movedItem = _filteredMenuItems[newItemIndex];

      // Als je naar lijst 0 gaat = "Alle items" → category_id null
      final newCategoryId =
          (newListIndex == 0) ? null : _categories[newListIndex - 1]['id'];

      await _apiService.updateMenuItem(
        movedItem['id'],
        {
          'category_id': newCategoryId,
          'position': newItemIndex,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item volgorde bijgewerkt'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // rollback als API faalt
      setState(() {
        final movedItem = _filteredMenuItems.removeAt(newItemIndex);
        _filteredMenuItems.insert(oldItemIndex, movedItem);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opslaan nieuwe positie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    final price = item['price']?.toDouble() ?? 0.0;
    final calories = item['calories']?.toInt() ?? 0;

    return Card(
      child: ListTile(
        leading: Icon(Icons.restaurant, color: AppColors.primary),
        title: Text(item['name'] ?? ''),
        subtitle: Text('€${price.toStringAsFixed(2)} - $calories kcal'),
        onTap: () => _editMenuItem(item),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return _categories.isEmpty
        ? const Center(child: Text('Geen Categorieën'))
        : ListView.builder(
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryCard(category);
            },
          );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.category, color: AppColors.primary),
        title: Text(category['name'] ?? ''),
        onTap: () => _editCategory(category),
      ),
    );
  }

  Widget _buildRecipesTab() {
    return const Center(child: Text('Recepten Beheer (binnenkort)'));
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
    context.push('/cateraar/menu-items/add?menu_id=${widget.menuId}');
  }

  void _editMenuItem(Map<String, dynamic> item) {
    context.push('/cateraar/menu-items/${item['id']}/edit');
  }

  void _addCategory() {
    context.push('/cateraar/categories/add?menu_id=${widget.menuId}');
  }

  void _editCategory(Map<String, dynamic> category) {
    context.push('/cateraar/categories/${category['id']}/edit');
  }

  void _addRecipe() {
    context.push('/cateraar/recipes/add');
  }
}
