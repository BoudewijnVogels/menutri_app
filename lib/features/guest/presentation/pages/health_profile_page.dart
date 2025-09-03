import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/health_calculations.dart';

class HealthProfilePage extends ConsumerStatefulWidget {
  const HealthProfilePage({super.key});

  @override
  ConsumerState<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends ConsumerState<HealthProfilePage> {
  final _formKey = GlobalKey<FormState>();
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

  final List<String> _dietaryOptions = [
    'Vegetarisch',
    'Veganistisch',
    'Glutenvrij',
    'Lactosevrij',
    'Keto',
    'Paleo',
    'Mediterraan',
    'Low-carb',
    'High-protein'
  ];

  final List<String> _allergyOptions = [
    'Noten',
    'Pinda\'s',
    'Schaaldieren',
    'Vis',
    'Eieren',
    'Melk',
    'Soja',
    'Gluten',
    'Sesam',
    'Sulfiet'
  ];

  final List<String> _conditionOptions = [
    'Diabetes type 1',
    'Diabetes type 2',
    'Hoge bloeddruk',
    'Hoog cholesterol',
    'Hartziekte',
    'Nierproblemen',
    'Andere'
  ];

  @override
  void initState() {
    super.initState();
    _loadHealthProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profile'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Health Profile Form Goes Here'),
                    if (_bmi != null) Text('BMI: ${_bmi!.toStringAsFixed(1)}'),
                    if (_recommendedCalories != null)
                      Text(
                          'Recommended Calories: ${_recommendedCalories!.toStringAsFixed(0)}'),
                    const SizedBox(height: 16),
                    Text('Dietary Options:',
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _dietaryOptions.length,
                        itemBuilder: (context, index) {
                          return Text(_dietaryOptions[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Allergy Options:',
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allergyOptions.length,
                        itemBuilder: (context, index) {
                          return Text(_allergyOptions[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Condition Options:',
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _conditionOptions.length,
                        itemBuilder: (context, index) {
                          return Text(_conditionOptions[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _loadHealthProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profile = await ApiService().getHealthProfile();

      _populateFormFromProfile(profile);
      _calculateHealthMetrics();

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
    // ——— NIEUW: velden invullen op basis van backend-profiel ———
    // NB: veilig parsen met defaults; verwijder niks uit jouw code.
    _ageController.text = (profile['age'] ?? '').toString();
    _heightController.text = (profile['height_cm'] ?? '').toString();
    _weightController.text = (profile['weight_kg'] ?? '').toString();
    _gender = (profile['gender'] ?? _gender).toString();

    _activityLevel = (profile['activity_level'] ?? _activityLevel).toString();
    _goal = (profile['goal'] ?? _goal).toString();
    _targetWeightController.text =
        (profile['target_weight_kg'] ?? '').toString();

    // Optioneel: als jouw backend arrays terugstuurt:
    final diets =
        (profile['dietary_preferences'] as List?)?.cast<String>() ?? [];
    final allergies = (profile['allergies'] as List?)?.cast<String>() ?? [];
    final conditions = (profile['conditions'] as List?)?.cast<String>() ?? [];
    _selectedDietaryPreferences
      ..clear()
      ..addAll(diets);
    _selectedAllergies
      ..clear()
      ..addAll(allergies);
    _selectedConditions
      ..clear()
      ..addAll(conditions);

    // Custom doelen
    _useCustomGoals = (profile['use_custom_goals'] ?? _useCustomGoals) == true;
    _dailyCaloriesController.text =
        (profile['daily_calories'] ?? '').toString();
    _dailyProteinController.text =
        (profile['daily_protein_g'] ?? '').toString();
    _dailyCarbsController.text = (profile['daily_carbs_g'] ?? '').toString();
    _dailyFatController.text = (profile['daily_fat_g'] ?? '').toString();

    // Data sharing toggles
    _shareWithMyFitnessPal =
        (profile['share_mfp'] ?? _shareWithMyFitnessPal) == true;
    _shareWithGoogleFit =
        (profile['share_google_fit'] ?? _shareWithGoogleFit) == true;
    _shareWithAppleHealth =
        (profile['share_apple_health'] ?? _shareWithAppleHealth) == true;
  }

  void _calculateHealthMetrics() {
    // ——— NIEUW: berekeningen via jouw HealthCalculations ———
    final age = int.tryParse(_ageController.text) ?? 0;
    final heightCm = double.tryParse(_heightController.text) ?? 0.0;
    final weightKg = double.tryParse(_weightController.text) ?? 0.0;

    _bmi = HealthCalculations.calculateBMI(weightKg, heightCm);

    _bmr = HealthCalculations.calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: _gender,
    );

    _tdee = HealthCalculations.calculateTDEE(
      _bmr ?? 0.0,
      _activityLevel,
    );

    _recommendedCalories = HealthCalculations.calculateDailyCalorieGoal(
      _tdee ?? 0.0,
      _goal,
    );

    setState(() {});
  }
}
