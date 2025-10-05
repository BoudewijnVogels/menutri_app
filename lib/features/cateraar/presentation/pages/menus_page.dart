import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class MenusPage extends ConsumerStatefulWidget {
  const MenusPage({super.key});

  @override
  ConsumerState<MenusPage> createState() => _MenusPageState();
}

class _MenusPageState extends ConsumerState<MenusPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _menus = [];

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getMenus();
      final menus = List<Map<String, dynamic>>.from(response['menus'] ?? []);

      setState(() {
        _menus = menus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden menukaarten: $e')),
        );
      }
    }
  }

  void _addMenu() {
    context.push('/cateraar/menus/add');
  }

  void _editMenu(Map<String, dynamic> menu) {
    final id = menu['id'];
    context.push('/cateraar/menus/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu’s'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menus.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMenus,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _menus.length,
                    itemBuilder: (context, index) {
                      final menu = _menus[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMenuCard(menu),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMenu,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nieuwe menukaart'),
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
            Icon(Icons.menu_book, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Geen menukaarten',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maak je eerste menukaart aan',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> menu) {
    final status = menu['status'] ?? 'concept';
    final updatedAt = menu['updated_at'] ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.menu_book, color: AppColors.primary),
        title: Text(
          menu['name'] ?? '',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text('Status: $status · Laatst gewijzigd: $updatedAt'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _editMenu(menu),
      ),
    );
  }
}
