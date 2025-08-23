import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/health_calculations.dart';

class HealthProfilePage extends ConsumerStatefulWidget {
  const HealthProfilePage({super.key});

  @override
  ConsumerState<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends ConsumerState<HealthProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Personal info
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = 'female';
  
  // Activity and goals
  String _activityLevel = 'sedentary';
  String _goal = 'maintain';
  final _targetWeightController = TextEditingController();
  
  // Dietary preferences
  final List<String> _selectedDietaryPreferences = [];
  final List<String> _selectedAllergies = [];
  final List<String> _selectedConditions = [];
  
  // Daily goals
  final _dailyCaloriesController = TextEditingController();
  final _dailyProteinController = TextEditingController();
  final _dailyCarbsController = TextEditingController();
  final _dailyFatController = TextEditingController();
  bool _useCustomGoals = false;
  
  // Data sharing
  bool _shareWithMyFitnessPal = false;
  bool _shareWithGoogleFit = false;
  bool _shareWithAppleHealth = false;
  
  // Calculated values
  double? _bmi;
  double? _bmr;
  double? _tdee;
  double? _recommendedCalories;
  
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _dietaryOptions = [
    'Vegetarisch', 'Veganistisch', 'Glutenvrij', 'Lactosevrij', 
    'Keto', 'Paleo', 'Mediterraan', 'Low-carb', 'High-protein'
  ];
  
  final List<String> _allergyOptions = [
    'Noten', 'Pinda\'s', 'Schaaldieren', 'Vis', 'Eieren', 
    'Melk', 'Soja', 'Gluten', 'Sesam', 'Sulfiet'
  ];
  
  final List<String> _conditionOptions = [
    'Diabetes type 1', 'Diabetes type 2', 'Hoge bloeddruk', 
    'Hoog cholesterol', 'Hartziekte', 'Nierproblemen', 'Andere'
  ];

  @override
  void initState() {
    super.initState();
    _loadHealthProfile();
  }

  Future<void> _loadHealthProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profile = await ApiService().getHealthProfile();
      
      if (profile != null) {
        _populateFormFromProfile(profile);
        _calculateHealthMetrics();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Profile doesn't exist yet, start with empty form
    }
  }

  void _populateFormFromProfile(Map<String, dynamic> profile) {
    _ageController.text = profile['age']?.toString() ?? '';
    _heightController.text = profile['height']?.toString() ?? '';
    _weightController.text = profile['weight']?.toString() ?? '';
    _gender = profile['gender'] ?? 'female';
    _activityLevel = profile['activity_level'] ?? 'sedentary';
    _goal = profile['goal'] ?? 'maintain';
    _targetWeightController.text = profile['target_weight']?.toString() ?? '';
    
    _selectedDietaryPreferences.clear();
    _selectedDietaryPreferences.addAll(
      List<String>.from(profile['dietary_preferences'] ?? [])
    );
    
    _selectedAllergies.clear();
    _selectedAllergies.addAll(
      List<String>.from(profile['allergies'] ?? [])
    );
    
    _selectedConditions.clear();
    _selectedConditions.addAll(
      List<String>.from(profile['conditions'] ?? [])
    );
    
    _dailyCaloriesController.text = profile['daily_calories']?.toString() ?? '';
    _dailyProteinController.text = profile['daily_protein']?.toString() ?? '';
    _dailyCarbsController.text = profile['daily_carbs']?.toString() ?? '';
    _dailyFatController.text = profile['daily_fat']?.toString() ?? '';
    _useCustomGoals = profile['use_custom_goals'] ?? false;
    
    _shareWithMyFitnessPal = profile['share_myfitnesspal'] ?? false;
    _shareWithGoogleFit = profile['share_google_fit'] ?? false;
    _shareWithAppleHealth = profile['share_apple_health'] ?? false;
  }

  void _calculateHealthMetrics() {
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    
    if (age != null && height != null && weight != null) {
      setState(() {
        _bmi = HealthCalculations.calculateBMI(weight, height);
        _bmr = HealthCalculations.calculateBMR(
          weightKg: weight,
          heightCm: height,
          age: age,
          gender: _gender,
        );
        _tdee = _bmr != null 
            ? HealthCalculations.calculateTDEE(_bmr!, _activityLevel)
            : null;
        _recommendedCalories = _tdee != null
            ? HealthCalculations.calculateDailyCalorieGoal(_tdee!, _goal)
            : null;
      });
      
      // Auto-fill daily goals if not using custom
      if (!_useCustomGoals && _recommendedCalories != null) {
        _dailyCaloriesController.text = _recommendedCalories!.round().toString();
        
        // Calculate macro distribution (example: 30% protein, 40% carbs, 30% fat)
        final protein = (_recommendedCalories! * 0.3 / 4).round();
        final carbs = (_recommendedCalories! * 0.4 / 4).round();
        final fat = (_recommendedCalories! * 0.3 / 9).round();
        
        _dailyProteinController.text = protein.toString();
        _dailyCarbsController.text = carbs.toString();
        _dailyFatController.text = fat.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gezondheidsprofiel'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Opslaan'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Health metrics cards (if calculated)
                    if (_bmi != null) _buildHealthMetricsCards(),
                    
                    const SizedBox(height: 24),
                    
                    // Personal information
                    _buildSection(
                      'Persoonlijke gegevens',
                      [
                        _buildAgeField(),
                        const SizedBox(height: 16),
                        _buildGenderField(),
                        const SizedBox(height: 16),
                        _buildHeightField(),
                        const SizedBox(height: 16),
                        _buildWeightField(),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Activity level
                    _buildSection(
                      'Activiteitsniveau',
                      [
                        _buildActivityLevelField(),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Goals
                    _buildSection(
                      'Doelen',
                      [
                        _buildGoalField(),
                        const SizedBox(height: 16),
                        if (_goal != 'maintain') _buildTargetWeightField(),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Dietary preferences
                    _buildSection(
                      'Voedingsvoorkeuren',
                      [
                        _buildMultiSelectChips(
                          'Dieet',
                          _dietaryOptions,
                          _selectedDietaryPreferences,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Allergies
                    _buildSection(
                      'Allergieën en intoleranties',
                      [
                        _buildMultiSelectChips(
                          'Allergieën',
                          _allergyOptions,
                          _selectedAllergies,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Medical conditions
                    _buildSection(
                      'Medische aandoeningen',
                      [
                        _buildMultiSelectChips(
                          'Aandoeningen',
                          _conditionOptions,
                          _selectedConditions,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Daily goals
                    _buildSection(
                      'Dagelijkse doelen',
                      [
                        _buildCustomGoalsToggle(),
                        const SizedBox(height: 16),
                        _buildDailyGoalsFields(),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Data sharing
                    _buildSection(
                      'Data delen',
                      [
                        _buildDataSharingToggles(),
                      ],
                    ),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthMetricsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'BMI',
                _bmi!.toStringAsFixed(1),
                HealthCalculations.getBMICategory(_bmi!),
                Color(int.parse(
                  HealthCalculations.getBMICategoryColor(_bmi!).substring(1),
                  radix: 16,
                ) + 0xFF000000),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'BMR',
                '${_bmr!.round()}',
                'kcal/dag',
                AppColors.mediumBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'TDEE',
                '${_tdee!.round()}',
                'kcal/dag',
                AppColors.darkBrown,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Doel',
                '${_recommendedCalories!.round()}',
                'kcal/dag',
                AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      decoration: const InputDecoration(
        labelText: 'Leeftijd',
        suffixText: 'jaar',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Voer je leeftijd in';
        }
        final age = int.tryParse(value);
        if (age == null || age < 13 || age > 120) {
          return 'Voer een geldige leeftijd in (13-120)';
        }
        return null;
      },
      onChanged: (_) => _calculateHealthMetrics(),
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Geslacht'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Vrouw'),
                value: 'female',
                groupValue: _gender,
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                  _calculateHealthMetrics();
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Man'),
                value: 'male',
                groupValue: _gender,
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                  _calculateHealthMetrics();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      controller: _heightController,
      decoration: const InputDecoration(
        labelText: 'Lengte',
        suffixText: 'cm',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Voer je lengte in';
        }
        final height = double.tryParse(value);
        if (height == null || height < 100 || height > 250) {
          return 'Voer een geldige lengte in (100-250 cm)';
        }
        return null;
      },
      onChanged: (_) => _calculateHealthMetrics(),
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      decoration: const InputDecoration(
        labelText: 'Gewicht',
        suffixText: 'kg',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Voer je gewicht in';
        }
        final weight = double.tryParse(value);
        if (weight == null || weight < 30 || weight > 300) {
          return 'Voer een geldig gewicht in (30-300 kg)';
        }
        return null;
      },
      onChanged: (_) => _calculateHealthMetrics(),
    );
  }

  Widget _buildActivityLevelField() {
    return DropdownButtonFormField<String>(
      value: _activityLevel,
      decoration: const InputDecoration(
        labelText: 'Activiteitsniveau',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'sedentary', child: Text('Zittend (weinig/geen sport)')),
        DropdownMenuItem(value: 'lightly_active', child: Text('Licht actief (1-3 dagen/week)')),
        DropdownMenuItem(value: 'moderately_active', child: Text('Matig actief (3-5 dagen/week)')),
        DropdownMenuItem(value: 'very_active', child: Text('Zeer actief (6-7 dagen/week)')),
        DropdownMenuItem(value: 'extremely_active', child: Text('Extreem actief (2x/dag, intensief)')),
      ],
      onChanged: (value) {
        setState(() {
          _activityLevel = value!;
        });
        _calculateHealthMetrics();
      },
    );
  }

  Widget _buildGoalField() {
    return DropdownButtonFormField<String>(
      value: _goal,
      decoration: const InputDecoration(
        labelText: 'Doel',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'lose_weight', child: Text('Afvallen')),
        DropdownMenuItem(value: 'maintain', child: Text('Gewicht behouden')),
        DropdownMenuItem(value: 'gain_weight', child: Text('Aankomen')),
      ],
      onChanged: (value) {
        setState(() {
          _goal = value!;
        });
        _calculateHealthMetrics();
      },
    );
  }

  Widget _buildTargetWeightField() {
    return TextFormField(
      controller: _targetWeightController,
      decoration: const InputDecoration(
        labelText: 'Streefgewicht',
        suffixText: 'kg',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildMultiSelectChips(String title, List<String> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    this.selected.add(option);
                  } else {
                    this.selected.remove(option);
                  }
                });
              },
              selectedColor: AppColors.mediumBrown.withOpacity(0.3),
              checkmarkColor: AppColors.mediumBrown,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomGoalsToggle() {
    return SwitchListTile(
      title: const Text('Aangepaste dagelijkse doelen'),
      subtitle: const Text('Stel je eigen macro doelen in'),
      value: _useCustomGoals,
      onChanged: (value) {
        setState(() {
          _useCustomGoals = value;
        });
        if (!value) {
          _calculateHealthMetrics();
        }
      },
      activeColor: AppColors.mediumBrown,
    );
  }

  Widget _buildDailyGoalsFields() {
    return Column(
      children: [
        TextFormField(
          controller: _dailyCaloriesController,
          decoration: const InputDecoration(
            labelText: 'Dagelijkse calorieën',
            suffixText: 'kcal',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          enabled: _useCustomGoals,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dailyProteinController,
                decoration: const InputDecoration(
                  labelText: 'Eiwit',
                  suffixText: 'g',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                enabled: _useCustomGoals,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dailyCarbsController,
                decoration: const InputDecoration(
                  labelText: 'Koolhydraten',
                  suffixText: 'g',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                enabled: _useCustomGoals,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dailyFatController,
                decoration: const InputDecoration(
                  labelText: 'Vet',
                  suffixText: 'g',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                enabled: _useCustomGoals,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataSharingToggles() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('MyFitnessPal'),
          subtitle: const Text('Deel voedingsgegevens met MyFitnessPal'),
          value: _shareWithMyFitnessPal,
          onChanged: (value) {
            setState(() {
              _shareWithMyFitnessPal = value;
            });
          },
          activeColor: AppColors.mediumBrown,
        ),
        SwitchListTile(
          title: const Text('Google Fit'),
          subtitle: const Text('Deel activiteitsgegevens met Google Fit'),
          value: _shareWithGoogleFit,
          onChanged: (value) {
            setState(() {
              _shareWithGoogleFit = value;
            });
          },
          activeColor: AppColors.mediumBrown,
        ),
        SwitchListTile(
          title: const Text('Apple Health'),
          subtitle: const Text('Deel gezondheidsgegevens met Apple Health'),
          value: _shareWithAppleHealth,
          onChanged: (value) {
            setState(() {
              _shareWithAppleHealth = value;
            });
          },
          activeColor: AppColors.mediumBrown,
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profileData = {
        'age': int.parse(_ageController.text),
        'height': double.parse(_heightController.text),
        'weight': double.parse(_weightController.text),
        'gender': _gender,
        'activity_level': _activityLevel,
        'goal': _goal,
        'target_weight': _targetWeightController.text.isNotEmpty 
            ? double.parse(_targetWeightController.text) 
            : null,
        'dietary_preferences': _selectedDietaryPreferences,
        'allergies': _selectedAllergies,
        'conditions': _selectedConditions,
        'daily_calories': _dailyCaloriesController.text.isNotEmpty 
            ? double.parse(_dailyCaloriesController.text) 
            : null,
        'daily_protein': _dailyProteinController.text.isNotEmpty 
            ? double.parse(_dailyProteinController.text) 
            : null,
        'daily_carbs': _dailyCarbsController.text.isNotEmpty 
            ? double.parse(_dailyCarbsController.text) 
            : null,
        'daily_fat': _dailyFatController.text.isNotEmpty 
            ? double.parse(_dailyFatController.text) 
            : null,
        'use_custom_goals': _useCustomGoals,
        'share_myfitnesspal': _shareWithMyFitnessPal,
        'share_google_fit': _shareWithGoogleFit,
        'share_apple_health': _shareWithAppleHealth,
        'bmi': _bmi,
        'bmr': _bmr,
        'tdee': _tdee,
      };

      await ApiService().updateHealthProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gezondheidsprofiel opgeslagen'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opslaan: $e'),
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
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _dailyCaloriesController.dispose();
    _dailyProteinController.dispose();
    _dailyCarbsController.dispose();
    _dailyFatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

