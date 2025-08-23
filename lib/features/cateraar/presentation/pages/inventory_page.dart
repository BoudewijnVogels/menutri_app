import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class CateraarInventoryPage extends ConsumerStatefulWidget {
  const CateraarInventoryPage({super.key});

  @override
  ConsumerState<CateraarInventoryPage> createState() => _CateraarInventoryPageState();
}

class _CateraarInventoryPageState extends ConsumerState<CateraarInventoryPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];
  
  String _selectedRestaurant = 'all';
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  String _sortBy = 'name';
  bool _sortAscending = true;

  final Map<String, String> _statusOptions = {
    'all': 'Alle',
    'in_stock': 'Op Voorraad',
    'low_stock': 'Laag',
    'out_of_stock': 'Uitverkocht',
    'expired': 'Verlopen',
    'expiring_soon': 'Verloopt Binnenkort',
  };

  final Map<String, String> _sortOptions = {
    'name': 'Naam',
    'quantity': 'Hoeveelheid',
    'expiry_date': 'Vervaldatum',
    'last_updated': 'Laatst Bijgewerkt',
    'cost': 'Kosten',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInventoryData();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryData() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getInventoryData();
      
      setState(() {
        _inventoryItems = List<Map<String, dynamic>>.from(response['inventory'] ?? []);
        _restaurants = List<Map<String, dynamic>>.from(response['restaurants'] ?? []);
        _categories = List<Map<String, dynamic>>.from(response['categories'] ?? []);
        _suppliers = List<Map<String, dynamic>>.from(response['suppliers'] ?? []);
        _isLoading = false;
      });
      
      _filterItems();
    } catch (e) {
      setState(() {
        _inventoryItems = _getDefaultInventoryItems();
        _restaurants = _getDefaultRestaurants();
        _categories = _getDefaultCategories();
        _suppliers = _getDefaultSuppliers();
        _isLoading = false;
      });
      _filterItems();
    }
  }

  List<Map<String, dynamic>> _getDefaultInventoryItems() {
    return [
      {
        'id': '1',
        'name': 'Tomaten',
        'category': 'Groenten',
        'quantity': 25,
        'unit': 'kg',
        'min_quantity': 10,
        'cost_per_unit': 2.50,
        'total_cost': 62.50,
        'supplier': 'Verse Groenten BV',
        'expiry_date': '2024-01-15',
        'last_updated': '2024-01-10',
        'status': 'in_stock',
        'restaurant_id': '1',
        'location': 'Koelkast A1',
        'barcode': '1234567890123',
      },
      {
        'id': '2',
        'name': 'Mozzarella',
        'category': 'Zuivel',
        'quantity': 5,
        'unit': 'kg',
        'min_quantity': 8,
        'cost_per_unit': 8.90,
        'total_cost': 44.50,
        'supplier': 'Kaas & Co',
        'expiry_date': '2024-01-12',
        'last_updated': '2024-01-09',
        'status': 'low_stock',
        'restaurant_id': '1',
        'location': 'Koelkast B2',
        'barcode': '2345678901234',
      },
      {
        'id': '3',
        'name': 'Basilicum',
        'category': 'Kruiden',
        'quantity': 0,
        'unit': 'bundels',
        'min_quantity': 5,
        'cost_per_unit': 1.20,
        'total_cost': 0.00,
        'supplier': 'Verse Kruiden',
        'expiry_date': '2024-01-08',
        'last_updated': '2024-01-08',
        'status': 'out_of_stock',
        'restaurant_id': '1',
        'location': 'Koelkast C1',
        'barcode': '3456789012345',
      },
      {
        'id': '4',
        'name': 'Olijfolie',
        'category': 'Oliën',
        'quantity': 12,
        'unit': 'flessen',
        'min_quantity': 5,
        'cost_per_unit': 6.50,
        'total_cost': 78.00,
        'supplier': 'Mediterrane Import',
        'expiry_date': '2025-06-15',
        'last_updated': '2024-01-05',
        'status': 'in_stock',
        'restaurant_id': '1',
        'location': 'Voorraadkast A',
        'barcode': '4567890123456',
      },
      {
        'id': '5',
        'name': 'Kip Filet',
        'category': 'Vlees',
        'quantity': 8,
        'unit': 'kg',
        'min_quantity': 10,
        'cost_per_unit': 12.50,
        'total_cost': 100.00,
        'supplier': 'Premium Vlees',
        'expiry_date': '2024-01-11',
        'last_updated': '2024-01-10',
        'status': 'expiring_soon',
        'restaurant_id': '1',
        'location': 'Vriezer A1',
        'barcode': '5678901234567',
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultRestaurants() {
    return [
      {'id': 'all', 'name': 'Alle Restaurants'},
      {'id': '1', 'name': 'Restaurant De Smaak'},
      {'id': '2', 'name': 'Café Central'},
      {'id': '3', 'name': 'Bistro Milano'},
    ];
  }

  List<Map<String, dynamic>> _getDefaultCategories() {
    return [
      {'id': 'all', 'name': 'Alle Categorieën'},
      {'id': 'vegetables', 'name': 'Groenten'},
      {'id': 'dairy', 'name': 'Zuivel'},
      {'id': 'meat', 'name': 'Vlees'},
      {'id': 'herbs', 'name': 'Kruiden'},
      {'id': 'oils', 'name': 'Oliën'},
      {'id': 'grains', 'name': 'Granen'},
      {'id': 'beverages', 'name': 'Dranken'},
    ];
  }

  List<Map<String, dynamic>> _getDefaultSuppliers() {
    return [
      {'id': '1', 'name': 'Verse Groenten BV', 'contact': '+31 20 123 4567'},
      {'id': '2', 'name': 'Kaas & Co', 'contact': '+31 20 234 5678'},
      {'id': '3', 'name': 'Verse Kruiden', 'contact': '+31 20 345 6789'},
      {'id': '4', 'name': 'Mediterrane Import', 'contact': '+31 20 456 7890'},
      {'id': '5', 'name': 'Premium Vlees', 'contact': '+31 20 567 8901'},
    ];
  }

  void _filterItems() {
    List<Map<String, dynamic>> filtered = List.from(_inventoryItems);
    
    // Search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((item) {
        return item['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
               item['category'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
               item['supplier'].toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    }
    
    // Restaurant filter
    if (_selectedRestaurant != 'all') {
      filtered = filtered.where((item) => item['restaurant_id'] == _selectedRestaurant).toList();
    }
    
    // Category filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((item) => item['category'].toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }
    
    // Status filter
    if (_selectedStatus != 'all') {
      filtered = filtered.where((item) => item['status'] == _selectedStatus).toList();
    }
    
    // Sort
    filtered.sort((a, b) {
      dynamic aValue = a[_sortBy];
      dynamic bValue = b[_sortBy];
      
      if (aValue is String && bValue is String) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (aValue is num && bValue is num) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      
      return 0;
    });
    
    setState(() {
      _filteredItems = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voorraad Beheer'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventoryData,
            tooltip: 'Vernieuwen',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportInventory();
                  break;
                case 'import':
                  _importInventory();
                  break;
                case 'bulk_update':
                  _bulkUpdateInventory();
                  break;
                case 'settings':
                  _showInventorySettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Exporteren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Importeren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_update',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Bulk Bewerken'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Instellingen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Zoek ingrediënten, categorieën, leveranciers...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterItems();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
              ),
              
              // Filters
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRestaurant,
                        decoration: const InputDecoration(
                          labelText: 'Restaurant',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.surface,
                        items: _restaurants.map((restaurant) {
                          return DropdownMenuItem<String>(
                            value: restaurant['id'],
                            child: Text(restaurant['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedRestaurant = value!);
                          _filterItems();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categorie',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.surface,
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'],
                            child: Text(category['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                          _filterItems();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.surface,
                        items: _statusOptions.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                          _filterItems();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.onPrimary,
                labelColor: AppColors.onPrimary,
                unselectedLabelColor: AppColors.onPrimary.withOpacity(0.7),
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Voorraad', icon: Icon(Icons.inventory, size: 16)),
                  Tab(text: 'Leveranciers', icon: Icon(Icons.local_shipping, size: 16)),
                  Tab(text: 'Bestellingen', icon: Icon(Icons.shopping_cart, size: 16)),
                  Tab(text: 'Rapporten', icon: Icon(Icons.analytics, size: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInventoryTab(),
                _buildSuppliersTab(),
                _buildOrdersTab(),
                _buildReportsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInventoryTab() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Geen voorraad items gevonden',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg items toe of pas je filters aan',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add),
              label: const Text('Item Toevoegen'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Sort Options
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Sorteer op:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _sortBy,
                underline: Container(),
                items: _sortOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  _filterItems();
                },
              ),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _sortAscending = !_sortAscending);
                  _filterItems();
                },
              ),
              const Spacer(),
              Text(
                '${_filteredItems.length} items',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Inventory List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              return _buildInventoryItemCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryItemCard(Map<String, dynamic> item) {
    Color statusColor;
    IconData statusIcon;
    
    switch (item['status']) {
      case 'in_stock':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'low_stock':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case 'out_of_stock':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.dangerous;
        break;
      case 'expiring_soon':
        statusColor = Colors.amber;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        item['category'],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _statusOptions[item['status']] ?? 'Onbekend',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editItem(item);
                        break;
                      case 'update_stock':
                        _updateStock(item);
                        break;
                      case 'reorder':
                        _reorderItem(item);
                        break;
                      case 'delete':
                        _deleteItem(item);
                        break;
                    }
                  },
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
                      value: 'update_stock',
                      child: ListTile(
                        leading: Icon(Icons.inventory),
                        title: Text('Voorraad Bijwerken'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reorder',
                      child: ListTile(
                        leading: Icon(Icons.shopping_cart),
                        title: Text('Herbestellen'),
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
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoeveelheid',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${item['quantity']} ${item['unit']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Min. Voorraad',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${item['min_quantity']} ${item['unit']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Totale Waarde',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '€${item['total_cost'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  item['location'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.local_shipping, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  item['supplier'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            if (item['expiry_date'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Vervalt: ${item['expiry_date']}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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

  Widget _buildSuppliersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suppliers.length,
      itemBuilder: (context, index) {
        final supplier = _suppliers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                supplier['name'][0],
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              supplier['name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(supplier['contact']),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'contact':
                    _contactSupplier(supplier);
                    break;
                  case 'order':
                    _orderFromSupplier(supplier);
                    break;
                  case 'edit':
                    _editSupplier(supplier);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'contact',
                  child: ListTile(
                    leading: Icon(Icons.phone),
                    title: Text('Contact'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'order',
                  child: ListTile(
                    leading: Icon(Icons.shopping_cart),
                    title: Text('Bestellen'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Bewerken'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Bestellingen',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bestellingen functionaliteit wordt binnenkort toegevoegd',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voorraad Rapporten',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildReportCard(
                'Totale Waarde',
                '€2,847.50',
                Icons.euro,
                Colors.green,
              ),
              _buildReportCard(
                'Items Laag',
                '12',
                Icons.warning,
                Colors.orange,
              ),
              _buildReportCard(
                'Uitverkocht',
                '3',
                Icons.error,
                Colors.red,
              ),
              _buildReportCard(
                'Verloopt Binnenkort',
                '5',
                Icons.schedule,
                Colors.amber,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Snelle Acties',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportInventory,
                          icon: const Icon(Icons.file_download),
                          label: const Text('Exporteren'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generateReport,
                          icon: const Icon(Icons.analytics),
                          label: const Text('Rapport'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Toevoegen'),
        content: const Text('Item toevoegen functionaliteit wordt binnenkort toegevoegd.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editItem(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} bewerken wordt binnenkort toegevoegd')),
    );
  }

  void _updateStock(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voorraad bijwerken voor ${item['name']} wordt binnenkort toegevoegd')),
    );
  }

  void _reorderItem(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} herbestellen wordt binnenkort toegevoegd')),
    );
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Verwijderen'),
        content: Text('Weet je zeker dat je ${item['name']} wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item['name']} verwijderd')),
              );
            },
            child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _contactSupplier(Map<String, dynamic> supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contact met ${supplier['name']} wordt binnenkort toegevoegd')),
    );
  }

  void _orderFromSupplier(Map<String, dynamic> supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bestellen bij ${supplier['name']} wordt binnenkort toegevoegd')),
    );
  }

  void _editSupplier(Map<String, dynamic> supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${supplier['name']} bewerken wordt binnenkort toegevoegd')),
    );
  }

  void _exportInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voorraad exporteren wordt binnenkort toegevoegd')),
    );
  }

  void _importInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voorraad importeren wordt binnenkort toegevoegd')),
    );
  }

  void _bulkUpdateInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk bewerken wordt binnenkort toegevoegd')),
    );
  }

  void _showInventorySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voorraad instellingen wordt binnenkort toegevoegd')),
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rapport genereren wordt binnenkort toegevoegd')),
    );
  }
}

