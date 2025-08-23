import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isDeleting = false;
  bool _hasReadWarning = false;
  
  final List<String> _deletionReasons = [
    'Ik gebruik de app niet meer',
    'Ik heb een ander account',
    'Privacy zorgen',
    'Te veel notificaties',
    'App werkt niet goed',
    'Andere reden',
  ];
  
  String? _selectedReason;
  final _otherReasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account verwijderen'),
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
              // Warning header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.error, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waarschuwing',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Het verwijderen van je account kan niet ongedaan worden gemaakt.',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // What will be deleted
              Text(
                'Wat wordt er verwijderd?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildDeletionItem('Je profiel en persoonlijke gegevens'),
              _buildDeletionItem('Al je favoriete restaurants en gerechten'),
              _buildDeletionItem('Je voedingslogboek en geschiedenis'),
              _buildDeletionItem('Je gezondheidsprofiel en doelen'),
              _buildDeletionItem('Alle app instellingen en voorkeuren'),
              _buildDeletionItem('Toegang tot je account en alle data'),
              
              const SizedBox(height: 24),
              
              // Deletion reason
              Text(
                'Waarom verwijder je je account? (optioneel)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Selecteer een reden',
                  border: OutlineInputBorder(),
                ),
                items: _deletionReasons.map((reason) {
                  return DropdownMenuItem(value: reason, child: Text(reason));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              ),
              
              if (_selectedReason == 'Andere reden') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otherReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Beschrijf je reden',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Alternatives section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBrown.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: AppColors.mediumBrown),
                        const SizedBox(width: 8),
                        Text(
                          'Alternatieven overwegen?',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAlternative(
                      'Notificaties uitschakelen',
                      'Schakel meldingen uit in je profiel instellingen',
                      Icons.notifications_off,
                    ),
                    _buildAlternative(
                      'Account tijdelijk deactiveren',
                      'Neem contact op met support voor tijdelijke deactivatie',
                      Icons.pause_circle_outline,
                    ),
                    _buildAlternative(
                      'Data exporteren',
                      'Download je gegevens voordat je je account verwijdert',
                      Icons.download,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Confirmation section
              Text(
                'Bevestiging',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Password confirmation
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Bevestig met je wachtwoord',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Voer je wachtwoord in om te bevestigen';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Type confirmation
              TextFormField(
                controller: _confirmationController,
                decoration: const InputDecoration(
                  labelText: 'Type "VERWIJDER" om te bevestigen',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.toUpperCase() != 'VERWIJDER') {
                    return 'Type "VERWIJDER" om te bevestigen';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Warning acknowledgment
              CheckboxListTile(
                value: _hasReadWarning,
                onChanged: (value) {
                  setState(() {
                    _hasReadWarning = value ?? false;
                  });
                },
                title: const Text(
                  'Ik begrijp dat het verwijderen van mijn account permanent is en niet ongedaan kan worden gemaakt.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.error,
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Annuleren'),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canDeleteAccount() ? _deleteAccount : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isDeleting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Verwijderen...'),
                              ],
                            )
                          : const Text('Account verwijderen'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Contact support
              Center(
                child: TextButton(
                  onPressed: _contactSupport,
                  child: const Text('Hulp nodig? Neem contact op met support'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.close, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildAlternative(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mediumBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canDeleteAccount() {
    return _hasReadWarning && 
           _passwordController.text.isNotEmpty && 
           _confirmationController.text.toUpperCase() == 'VERWIJDER' &&
           !_isDeleting;
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Final confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laatste bevestiging'),
        content: const Text(
          'Dit is je laatste kans. Weet je zeker dat je je account permanent wilt verwijderen? '
          'Deze actie kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ja, verwijder mijn account'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final deletionData = {
        'password': _passwordController.text,
        'reason': _selectedReason,
        'other_reason': _selectedReason == 'Andere reden' ? _otherReasonController.text : null,
      };

      await ApiService().deleteAccount(deletionData);

      if (mounted) {
        // Show success message and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Je account is succesvol verwijderd'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Clear all navigation stack and go to login
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Kon account niet verwijderen';
        
        // Handle specific error cases
        if (e.toString().contains('invalid_password')) {
          errorMessage = 'Wachtwoord is onjuist';
        } else if (e.toString().contains('account_not_found')) {
          errorMessage = 'Account niet gevonden';
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
        _isDeleting = false;
      });
    }
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact opnemen'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Je kunt contact opnemen met ons support team:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: AppColors.mediumBrown),
                SizedBox(width: 8),
                Text('support@menutri.app'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.mediumBrown),
                SizedBox(width: 8),
                Text('Ma-Vr 9:00-17:00'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }
}

