import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isChanging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wachtwoord wijzigen'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.withAlphaFraction(lightBrown, 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.mediumBrown),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wachtwoord vereisten',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Je nieuwe wachtwoord moet minimaal 8 karakters lang zijn en een combinatie bevatten van letters, cijfers en speciale tekens.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Current password
              Text(
                'Huidig wachtwoord',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Huidig wachtwoord',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Voer je huidige wachtwoord in';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // New password
              Text(
                'Nieuw wachtwoord',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Nieuw wachtwoord',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Voer een nieuw wachtwoord in';
                  }
                  if (value.length < 8) {
                    return 'Wachtwoord moet minimaal 8 karakters zijn';
                  }
                  if (!_isPasswordStrong(value)) {
                    return 'Wachtwoord moet letters, cijfers en speciale tekens bevatten';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(
                      () {}); // Trigger rebuild for password strength indicator
                },
              ),

              const SizedBox(height: 8),

              // Password strength indicator
              if (_newPasswordController.text.isNotEmpty)
                _buildPasswordStrengthIndicator(),

              const SizedBox(height: 16),

              // Confirm password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Bevestig nieuw wachtwoord',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bevestig je nieuwe wachtwoord';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Wachtwoorden komen niet overeen';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Change password button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChanging ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mediumBrown,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isChanging
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Wachtwoord wijzigen...'),
                          ],
                        )
                      : const Text('Wachtwoord wijzigen'),
                ),
              ),

              const SizedBox(height: 16),

              // Security tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security,
                            color: AppColors.mediumBrown),
                        const SizedBox(width: 8),
                        Text(
                          'Beveiligingstips',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSecurityTip(
                        'Gebruik een uniek wachtwoord voor Menutri'),
                    _buildSecurityTip('Deel je wachtwoord nooit met anderen'),
                    _buildSecurityTip('Wijzig je wachtwoord regelmatig'),
                    _buildSecurityTip(
                        'Gebruik een wachtwoordmanager voor extra beveiliging'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _newPasswordController.text;
    final strength = _calculatePasswordStrength(password);

    Color strengthColor;
    String strengthText;

    if (strength < 0.3) {
      strengthColor = AppColors.error;
      strengthText = 'Zwak';
    } else if (strength < 0.7) {
      strengthColor = AppColors.warning;
      strengthText = 'Gemiddeld';
    } else {
      strengthColor = AppColors.success;
      strengthText = 'Sterk';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Wachtwoordsterkte: ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              strengthText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: strengthColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength,
          backgroundColor: AppColors.lightGrey,
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
        ),
      ],
    );
  }

  Widget _buildSecurityTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.mediumBrown)),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  bool _isPasswordStrong(String password) {
    // Check for at least one letter, one number, and one special character
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasLetter && hasNumber && hasSpecialChar;
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0.0;

    // Length check
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;

    // Bonus for no repeated characters
    if (!RegExp(r'(.)\1{2,}').hasMatch(password)) strength += 0.1;

    return strength.clamp(0.0, 1.0);
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChanging = true;
    });

    try {
      await ApiService().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wachtwoord succesvol gewijzigd'),
            backgroundColor: AppColors.success,
          ),
        );

        // Go back to previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Kon wachtwoord niet wijzigen';

        // Handle specific error cases
        if (e.toString().contains('current_password')) {
          errorMessage = 'Huidig wachtwoord is onjuist';
        } else if (e.toString().contains('weak_password')) {
          errorMessage = 'Nieuw wachtwoord is te zwak';
        } else if (e.toString().contains('same_password')) {
          errorMessage = 'Nieuw wachtwoord moet anders zijn dan het huidige';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isChanging = false;
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
