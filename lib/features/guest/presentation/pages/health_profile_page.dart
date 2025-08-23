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
