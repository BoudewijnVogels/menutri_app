import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _voornaamController = TextEditingController();
  final _achternaamController = TextEditingController();
  final _restaurantNaamController = TextEditingController();
  final _telefoonController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = AppConstants.guestRole;
  String? _errorMessage;

  // ✅ helper voor iconkleur
  Color _getIconColor(Color bgColor) {
    return bgColor.computeLuminance() < 0.5
        ? AppColors.white
        : AppColors.mediumBrown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),

                        // Header
                        Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.mediumBrown,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.person_add,
                                size: 40,
                                color: _getIconColor(AppColors.mediumBrown),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Account aanmaken',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: AppColors.darkBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Maak een account aan om te beginnen',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.withAlphaFraction(
                                        AppColors.darkBrown, 0.7),
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Role selection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ik ben een:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Gast'),
                                        subtitle:
                                            const Text('Ontdek restaurants'),
                                        value: AppConstants.guestRole,
                                        groupValue: _selectedRole,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRole = value!;
                                          });
                                        },
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Cateraar'),
                                        subtitle: const Text('Beheer menu\'s'),
                                        value: AppConstants.cateraarRole,
                                        groupValue: _selectedRole,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRole = value!;
                                          });
                                        },
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'E-mailadres *',
                            prefixIcon: Icon(Icons.mail_outline,
                                color: AppColors.mediumBrown),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Voer je e-mailadres in';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Voer een geldig e-mailadres in';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Wachtwoord *',
                            prefixIcon: const Icon(Icons.lock,
                                color: AppColors.mediumBrown),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off,
                                color: AppColors.mediumBrown,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Voer een wachtwoord in';
                            }
                            if (value.length < 8) {
                              return 'Wachtwoord moet minimaal 8 tekens zijn';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Confirm password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Bevestig wachtwoord *',
                            prefixIcon: const Icon(Icons.lock_outlined,
                                color: AppColors.mediumBrown),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off,
                                color: AppColors.mediumBrown,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bevestig je wachtwoord';
                            }
                            if (value != _passwordController.text) {
                              return 'Wachtwoorden komen niet overeen';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Name fields
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _voornaamController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText:
                                      _selectedRole == AppConstants.cateraarRole
                                          ? 'Voornaam *'
                                          : 'Voornaam',
                                  prefixIcon: const Icon(Icons.person,
                                      color: AppColors.mediumBrown),
                                ),
                                validator: _selectedRole ==
                                        AppConstants.cateraarRole
                                    ? (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Voer je voornaam in';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _achternaamController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText:
                                      _selectedRole == AppConstants.cateraarRole
                                          ? 'Achternaam *'
                                          : 'Achternaam',
                                  prefixIcon: const Icon(Icons.person,
                                      color: AppColors.mediumBrown),
                                ),
                                validator: _selectedRole ==
                                        AppConstants.cateraarRole
                                    ? (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Voer je achternaam in';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        // Cateraar velden
                        if (_selectedRole == AppConstants.cateraarRole) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _restaurantNaamController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Restaurant naam *',
                              prefixIcon: Icon(Icons.restaurant,
                                  color: AppColors.mediumBrown),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Voer de restaurant naam in';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _telefoonController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Telefoonnummer *',
                              prefixIcon: Icon(Icons.phone,
                                  color: AppColors.mediumBrown),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Voer je telefoonnummer in';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.withAlphaFraction(
                                  AppColors.error, 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.withAlphaFraction(
                                    AppColors.error, 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Vaste knoppen onderaan
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: AppConstants.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white),
                                ),
                              )
                            : const Text('Account aanmaken'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Heb je al een account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: const Text('Inloggen'),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        firstName: _voornaamController.text.trim().isNotEmpty
            ? _voornaamController.text.trim()
            : null,
        lastName: _achternaamController.text.trim().isNotEmpty
            ? _achternaamController.text.trim()
            : null,
        restaurantName: _selectedRole == AppConstants.cateraarRole
            ? _restaurantNaamController.text.trim()
            : null,
        phone: _selectedRole == AppConstants.cateraarRole
            ? _telefoonController.text.trim()
            : null,
      );

      if (!mounted) return;

      ref.read(authStateProvider.notifier).state = true;

      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: response['access_token'],
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: response['refresh_token'],
      );

      final user = response['user'];
      final role = user['role'] as String;

      await _storage.write(
        key: AppConstants.userRoleKey,
        value: role,
      );
      await _storage.write(
        key: AppConstants.userIdKey,
        value: user['id'].toString(),
      );

      ref.read(userRoleProvider.notifier).state = role;

      if (!mounted) return;

      if (role == AppConstants.guestRole) {
        context.go(AppRoutes.guestHome);
      } else if (role == AppConstants.cateraarRole) {
        context.go(AppRoutes.cateraarDashboard);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.registerSuccessMessage),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().contains('DioException')
            ? 'Registratie mislukt. Controleer je gegevens en probeer opnieuw.'
            : e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _voornaamController.dispose();
    _achternaamController.dispose();
    _restaurantNaamController.dispose();
    _telefoonController.dispose();
    super.dispose();
  }
}
