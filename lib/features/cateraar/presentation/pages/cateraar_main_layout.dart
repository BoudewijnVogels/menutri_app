import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class CateraarMainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String location;

  const CateraarMainLayout({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  ConsumerState<CateraarMainLayout> createState() => _CateraarMainLayoutState();
}

class _CateraarMainLayoutState extends ConsumerState<CateraarMainLayout> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/cateraar/dashboard',
    ),
    NavigationItem(
      icon: Icons.restaurant,
      activeIcon: Icons.restaurant,
      label: 'Restaurants',
      route: '/cateraar/restaurants',
    ),
    NavigationItem(
      icon: Icons.menu_book,
      activeIcon: Icons.menu_book,
      label: 'Menu\'s',
      route: '/cateraar/menus',
    ),
    NavigationItem(
      icon: Icons.analytics,
      activeIcon: Icons.analytics,
      label: 'Analytics',
      route: '/cateraar/analytics',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = widget.location;
    for (int i = 0; i < _navigationItems.length; i++) {
      if (location.startsWith(_navigationItems[i].route)) {
        setState(() {
          _selectedIndex = i;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.withAlphaFraction(Colors.black, 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < _navigationItems.length; i++)
                _buildNavigationItem(i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(int index) {
    final item = _navigationItems[index];
    final isSelected = _selectedIndex == index;

    final iconColor = isSelected ? AppColors.white : AppColors.textSecondary;
    final labelColor = isSelected ? AppColors.white : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // Show different FAB based on current page
    switch (_selectedIndex) {
      case 0: // Dashboard
        return FloatingActionButton(
          onPressed: () => _showQuickActions(),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add),
        );
      case 1: // Restaurants
        return FloatingActionButton.extended(
          onPressed: () => context.push('/cateraar/restaurants/add'),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('Restaurant'),
        );
      case 2: // Menus
        return FloatingActionButton.extended(
          onPressed: () => context.push('/cateraar/menus/add'),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('Menu Toevoegen'),
        );
      case 3: // Analytics
        return FloatingActionButton(
          onPressed: () => _exportAnalytics(),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.file_download),
        );
      default:
        return FloatingActionButton(
          onPressed: () => _showQuickActions(),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add),
        );
    }
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      context.go(_navigationItems[index].route);
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickActionsBottomSheet(),
    );
  }

  void _exportAnalytics() {
    showDialog(
      context: context,
      builder: (context) => _ExportAnalyticsDialog(),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class _QuickActionsBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Snelle Acties',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildQuickActionCard(
                      context,
                      icon: Icons.restaurant,
                      title: 'Nieuw Restaurant',
                      subtitle: 'Restaurant toevoegen',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/cateraar/restaurants/add');
                      },
                    ),
                    _buildQuickActionCard(
                      context,
                      icon: Icons.menu_book,
                      title: 'Menu Item',
                      subtitle: 'Gerecht toevoegen',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/cateraar/menu-items/add');
                      },
                    ),
                    _buildQuickActionCard(
                      context,
                      icon: Icons.qr_code,
                      title: 'QR Code',
                      subtitle: 'Menu QR genereren',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/cateraar/qr-generator');
                      },
                    ),
                    _buildQuickActionCard(
                      context,
                      icon: Icons.analytics,
                      title: 'Rapport',
                      subtitle: 'Analytics bekijken',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/cateraar/analytics');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportAnalyticsDialog extends StatefulWidget {
  @override
  State<_ExportAnalyticsDialog> createState() => _ExportAnalyticsDialogState();
}

class _ExportAnalyticsDialogState extends State<_ExportAnalyticsDialog> {
  String _selectedPeriod = 'last_30_days';
  String _selectedFormat = 'csv';
  bool _isExporting = false;

  final Map<String, String> _periods = {
    'last_7_days': 'Laatste 7 dagen',
    'last_30_days': 'Laatste 30 dagen',
    'last_3_months': 'Laatste 3 maanden',
    'last_year': 'Laatste jaar',
    'custom': 'Aangepaste periode',
  };

  final Map<String, String> _formats = {
    'csv': 'CSV (Excel)',
    'pdf': 'PDF Rapport',
    'json': 'JSON Data',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Analytics Exporteren'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selecteer periode:'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedPeriod,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _periods.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPeriod = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('Selecteer formaat:'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedFormat,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _formats.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFormat = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _exportData,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
          ),
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Exporteren'),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      // Simuleer exportproces
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Analytics geëxporteerd als ${_formats[_selectedFormat]}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij exporteren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
