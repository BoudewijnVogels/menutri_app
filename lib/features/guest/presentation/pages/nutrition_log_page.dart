import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'nutrition_log.dart';
import 'health_profile.dart';

class NutritionLogPage extends ConsumerStatefulWidget {
  const NutritionLogPage({super.key});

  @override
  ConsumerState<NutritionLogPage> createState() => _NutritionLogPageState();
}

class _NutritionLogPageState extends ConsumerState<NutritionLogPage> {
  final ApiService _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  List<NutritionLog> _nutritionLogs = [];
  HealthProfile? _healthProfile;
  DailySummary? _dailySummary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.getNutritionLogs(),
        _apiService.getHealthProfile(),
      ]);

      final logsData = futures[0]['nutrition_logs'] as List;
      final profileData = futures[1]['health_profile'];

      setState(() {
        _nutritionLogs =
            logsData.map((log) => NutritionLog.fromJson(log)).toList();
        _healthProfile =
            profileData != null ? HealthProfile.fromJson(profileData) : null;
        _dailySummary = DailySummary.fromLogs(_selectedDate, _nutritionLogs);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voedingslogboek'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showNutritionAnalytics(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date selector
                    _buildDateSelector(),
                    const SizedBox(height: 24),

                    // Daily summary
                    if (_dailySummary != null) _buildDailySummary(),
                    const SizedBox(height: 24),

                    // Meals
                    _buildMealSection('breakfast', 'Ontbijt', Icons.wb_sunny),
                    const SizedBox(height: 16),
                    _buildMealSection(
                        'lunch', 'Lunch', Icons.wb_sunny_outlined),
                    const SizedBox(height: 16),
                    _buildMealSection('dinner', 'Diner', Icons.nights_stay),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDailySummary() {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dagoverzicht',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // ✅ Gecorrigeerde getters op DailySummary
            Text('Calorieën: ${_dailySummary?.totalCalories ?? 0} kcal'),
            Text('Eiwitten: ${_dailySummary?.totalProtein ?? 0} g'),
            Text('Koolhydraten: ${_dailySummary?.totalCarbs ?? 0} g'),
            Text('Vetten: ${_dailySummary?.totalFat ?? 0} g'),
            if (_healthProfile != null) ...[
              const SizedBox(height: 8),
              // ✅ HealthProfile heeft geen 'name'; toon iets dat wel bestaat
              Text('Geslacht: ${_healthProfile!.gender ?? ''}'),
              Text('Leeftijd: ${_healthProfile!.age ?? ''}'),
            ],
          ],
        ),
      ),
    );
  }

  void _showNutritionAnalytics() {
    // TODO: Implement analytics navigation or dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics feature coming soon!')),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat.yMMMMd('nl').format(_selectedDate),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(context),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dailySummary = DailySummary.fromLogs(_selectedDate, _nutritionLogs);
      });
    }
  }

  Widget _buildMealSection(String mealType, String title, IconData icon) {
    // ✅ NutritionLog heeft 'mealDate' (en 'loggedAt'), niet 'date'
    final mealLogs = _nutritionLogs
        .where((log) =>
            log.mealType == mealType &&
            log.mealDate.year == _selectedDate.year &&
            log.mealDate.month == _selectedDate.month &&
            log.mealDate.day == _selectedDate.day)
        .toList();

    return Card(
      color: AppColors.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (mealLogs.isEmpty) const Text('Geen items toegevoegd.'),
            for (var log in mealLogs)
              ListTile(
                title: Text(log.foodName ?? ''),
                subtitle: Text('${log.calories} kcal'),
              ),
          ],
        ),
      ),
    );
  }
}
