import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/health_calculations.dart';

class NutritionLogPage extends ConsumerStatefulWidget {
  const NutritionLogPage({super.key});

  @override
  ConsumerState<NutritionLogPage> createState() => _NutritionLogPageState();
}

class _NutritionLogPageState extends ConsumerState<NutritionLogPage> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _nutritionLogs = [];
  Map<String, dynamic>? _dailySummary;
  Map<String, dynamic>? _healthProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
    _loadHealthProfile();
  }

  Future<void> _loadNutritionData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final dateString = _selectedDate.toIso8601String().split('T')[0];
      final logs = await ApiService().getNutritionLogs(date: dateString);
      final summary = await ApiService().getDailySummary(date: dateString);
      
      setState(() {
        _nutritionLogs = logs;
        _dailySummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kon voedingslogboek niet laden: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHealthProfile() async {
    try {
      final profile = await ApiService().getHealthProfile();
      setState(() {
        _healthProfile = profile;
      });
    } catch (e) {
      // Health profile is optional
      print('Could not load health profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voedingslogboek'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector and summary
          _buildDateAndSummarySection(),
          
          // Nutrition logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildNutritionLogsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealDialog,
        backgroundColor: AppColors.mediumBrown,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateAndSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Column(
        children: [
          // Date selector
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousDay,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _showDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightGrey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: AppColors.grey),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(_selectedDate),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _isToday() ? null : _nextDay,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Daily summary cards
          if (_dailySummary != null) _buildDailySummaryCards(),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCards() {
    final summary = _dailySummary!;
    final totalCalories = summary['total_calories'] as num? ?? 0;
    final totalProtein = summary['total_protein'] as num? ?? 0;
    final totalCarbs = summary['total_carbs'] as num? ?? 0;
    final totalFat = summary['total_fat'] as num? ?? 0;
    
    // Get daily goals from health profile
    final dailyCalorieGoal = _healthProfile?['daily_calories'] as num? ?? 2000;
    final dailyProteinGoal = _healthProfile?['daily_protein'] as num? ?? 150;
    final dailyCarbsGoal = _healthProfile?['daily_carbs'] as num? ?? 250;
    final dailyFatGoal = _healthProfile?['daily_fat'] as num? ?? 65;

    return Column(
      children: [
        // Calories progress
        _buildProgressCard(
          'Calorieën',
          totalCalories.toDouble(),
          dailyCalorieGoal.toDouble(),
          'kcal',
          AppColors.mediumBrown,
        ),
        
        const SizedBox(height: 12),
        
        // Macros progress
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                'Eiwit',
                totalProtein.toDouble(),
                dailyProteinGoal.toDouble(),
                'g',
                AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildProgressCard(
                'Koolhydraten',
                totalCarbs.toDouble(),
                dailyCarbsGoal.toDouble(),
                'g',
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildProgressCard(
                'Vet',
                totalFat.toDouble(),
                dailyFatGoal.toDouble(),
                'g',
                AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(String title, double current, double goal, String unit, Color color) {
    final percentage = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = (goal - current).clamp(0.0, double.infinity);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            
            // Progress indicator
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Values
            Text(
              '${current.round()} / ${goal.round()} $unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            if (remaining > 0)
              Text(
                '${remaining.round()} $unit resterend',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionLogsList() {
    if (_nutritionLogs.isEmpty) {
      return _buildEmptyState();
    }

    // Group logs by meal type
    final groupedLogs = <String, List<dynamic>>{};
    for (final log in _nutritionLogs) {
      final mealType = log['meal_type'] ?? 'Overig';
      groupedLogs[mealType] = groupedLogs[mealType] ?? [];
      groupedLogs[mealType]!.add(log);
    }

    final mealOrder = ['Ontbijt', 'Lunch', 'Diner', 'Snacks', 'Overig'];
    final sortedMealTypes = mealOrder.where((meal) => groupedLogs.containsKey(meal)).toList();

    return RefreshIndicator(
      onRefresh: _loadNutritionData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedMealTypes.length,
        itemBuilder: (context, index) {
          final mealType = sortedMealTypes[index];
          final logs = groupedLogs[mealType]!;
          
          return _buildMealSection(mealType, logs);
        },
      ),
    );
  }

  Widget _buildMealSection(String mealType, List<dynamic> logs) {
    final totalCalories = logs.fold<double>(0, (sum, log) => sum + (log['calories'] as num? ?? 0));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal header
            Row(
              children: [
                Icon(_getMealIcon(mealType), color: AppColors.mediumBrown),
                const SizedBox(width: 8),
                Text(
                  mealType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${totalCalories.round()} kcal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Meal items
            ...logs.map((log) => _buildLogItem(log)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final calories = log['calories'] as num? ?? 0;
    final protein = log['protein'] as num? ?? 0;
    final carbs = log['carbs'] as num? ?? 0;
    final fat = log['fat'] as num? ?? 0;
    final createdAt = DateTime.tryParse(log['created_at'] ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['dish_name'] ?? log['food_name'] ?? 'Onbekend gerecht',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMacroChip('${calories.round()} kcal', AppColors.mediumBrown),
                    const SizedBox(width: 8),
                    _buildMacroChip('P: ${protein.round()}g', AppColors.success),
                    const SizedBox(width: 8),
                    _buildMacroChip('K: ${carbs.round()}g', AppColors.warning),
                    const SizedBox(width: 8),
                    _buildMacroChip('V: ${fat.round()}g', AppColors.error),
                  ],
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Bewerken'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Verwijderen'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _editLogItem(log);
              } else if (value == 'delete') {
                _deleteLogItem(log['id']);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, size: 64, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(
            'Geen maaltijden gelogd',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Voeg je eerste maaltijd toe met de + knop',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNutritionData,
            child: const Text('Opnieuw proberen'),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'ontbijt':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'diner':
        return Icons.dinner_dining;
      case 'snacks':
        return Icons.cookie;
      default:
        return Icons.restaurant_menu;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Vandaag';
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'Gisteren';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return 'Morgen';
    } else {
      final weekdays = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
      final months = ['Jan', 'Feb', 'Mrt', 'Apr', 'Mei', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dec'];
      
      return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
    }
  }

  bool _isToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selectedDay == today;
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadNutritionData();
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadNutritionData();
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadNutritionData();
    }
  }

  void _showAddMealDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddMealDialog(
        selectedDate: _selectedDate,
        onMealAdded: _loadNutritionData,
      ),
    );
  }

  void _editLogItem(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => _EditMealDialog(
        log: log,
        onMealUpdated: _loadNutritionData,
      ),
    );
  }

  Future<void> _deleteLogItem(int logId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maaltijd verwijderen'),
        content: const Text('Weet je zeker dat je deze maaltijd wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().deleteNutritionLog(logId);
        _loadNutritionData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maaltijd verwijderd'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kon maaltijd niet verwijderen: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// Add Meal Dialog
class _AddMealDialog extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onMealAdded;

  const _AddMealDialog({
    required this.selectedDate,
    required this.onMealAdded,
  });

  @override
  State<_AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<_AddMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  String _selectedMealType = 'Ontbijt';
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Maaltijd toevoegen'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Maaltijdtype',
                  border: OutlineInputBorder(),
                ),
                items: ['Ontbijt', 'Lunch', 'Diner', 'Snacks'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMealType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Naam',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Voer een naam in';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calorieën',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Verplicht';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Eiwit (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Koolhydraten (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Vet (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuleren'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveMeal,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Opslaan'),
        ),
      ],
    );
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final mealData = {
        'meal_type': _selectedMealType,
        'food_name': _nameController.text,
        'calories': double.parse(_caloriesController.text),
        'protein': _proteinController.text.isNotEmpty ? double.parse(_proteinController.text) : 0,
        'carbs': _carbsController.text.isNotEmpty ? double.parse(_carbsController.text) : 0,
        'fat': _fatController.text.isNotEmpty ? double.parse(_fatController.text) : 0,
        'logged_at': widget.selectedDate.toIso8601String(),
      };

      await ApiService().addNutritionLog(mealData);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onMealAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maaltijd toegevoegd'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kon maaltijd niet toevoegen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }
}

// Edit Meal Dialog
class _EditMealDialog extends StatefulWidget {
  final Map<String, dynamic> log;
  final VoidCallback onMealUpdated;

  const _EditMealDialog({
    required this.log,
    required this.onMealUpdated,
  });

  @override
  State<_EditMealDialog> createState() => _EditMealDialogState();
}

class _EditMealDialogState extends State<_EditMealDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  
  late String _selectedMealType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.log['food_name'] ?? widget.log['dish_name'] ?? '');
    _caloriesController = TextEditingController(text: widget.log['calories']?.toString() ?? '');
    _proteinController = TextEditingController(text: widget.log['protein']?.toString() ?? '');
    _carbsController = TextEditingController(text: widget.log['carbs']?.toString() ?? '');
    _fatController = TextEditingController(text: widget.log['fat']?.toString() ?? '');
    _selectedMealType = widget.log['meal_type'] ?? 'Ontbijt';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Maaltijd bewerken'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Maaltijdtype',
                  border: OutlineInputBorder(),
                ),
                items: ['Ontbijt', 'Lunch', 'Diner', 'Snacks'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMealType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Naam',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Voer een naam in';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calorieën',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Verplicht';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Eiwit (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Koolhydraten (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Vet (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuleren'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _updateMeal,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Opslaan'),
        ),
      ],
    );
  }

  Future<void> _updateMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final mealData = {
        'meal_type': _selectedMealType,
        'food_name': _nameController.text,
        'calories': double.parse(_caloriesController.text),
        'protein': _proteinController.text.isNotEmpty ? double.parse(_proteinController.text) : 0,
        'carbs': _carbsController.text.isNotEmpty ? double.parse(_carbsController.text) : 0,
        'fat': _fatController.text.isNotEmpty ? double.parse(_fatController.text) : 0,
      };

      await ApiService().updateNutritionLog(widget.log['id'], mealData);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onMealUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maaltijd bijgewerkt'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kon maaltijd niet bijwerken: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }
}

