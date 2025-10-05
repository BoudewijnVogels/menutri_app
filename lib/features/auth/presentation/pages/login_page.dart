import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    ApiService().initialize();
  }

  // ✅ helper: kies iconkleur op basis van achtergrond
  Color _getIconColor(Color bgColor) {
    return bgColor.computeLuminance() < 0.5
        ? AppColors.white
        : AppColors.mediumBrown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.lightGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo + title
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
                        Icons.restaurant,
                        size: 40,
                        color: _getIconColor(AppColors.mediumBrown),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welkom terug',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.darkBrown,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log in om door te gaan naar Menutri',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.withAlphaFraction(
                                AppColors.darkBrown, 0.7),
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'E-mailadres',
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
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Wachtwoord',
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
                            return 'Voer je wachtwoord in';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Wachtwoord vergeten functie komt binnenkort'),
                              ),
                            );
                          },
                          child: const Text('Wachtwoord vergeten?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.withAlphaFraction(
                                AppColors.error, 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.withAlphaFraction(
                                    AppColors.error, 0.3)),
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
                                      ?.copyWith(
                                        color: AppColors.error,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: AppConstants.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
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
                              : const Text('Inloggen'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'of',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.grey,
                                  ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: AppConstants.buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => context.go(AppRoutes.register),
                          child: const Text('Account aanmaken'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.onboarding),
                    child: const Text('Terug naar start'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
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
          content: Text(AppConstants.loginSuccessMessage),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().contains('DioException')
            ? 'Ongeldige inloggegevens. Controleer je e-mailadres en wachtwoord.'
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
    super.dispose();
  }
}
