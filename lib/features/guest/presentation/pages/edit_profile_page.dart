import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedLanguage = 'nl';
  File? _selectedImage;
  String? _currentAvatarUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final List<Map<String, String>> _languages = [
    {'code': 'nl', 'name': 'Nederlands', 'flag': '🇳🇱'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profile = await ApiService().getCurrentUser();

      setState(() {
        _nameController.text = profile['name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _selectedLanguage = profile['language'] ?? 'nl';
        _currentAvatarUrl = profile['avatar_url'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kon profiel niet laden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel bewerken'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
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
          : _errorMessage != null
              ? _buildErrorState()
              : _buildProfileForm(),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile photo section
            _buildPhotoSection(),

            const SizedBox(height: 32),

            // Personal information
            Text(
              'Persoonlijke gegevens',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naam',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Voer je naam in';
                }
                if (value.trim().length < 2) {
                  return 'Naam moet minimaal 2 karakters zijn';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email field (readonly)
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mailadres',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                helperText: 'E-mailadres kan niet worden gewijzigd',
              ),
              enabled: false,
            ),

            const SizedBox(height: 32),

            // App preferences
            Text(
              'App voorkeuren',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Language selection
            _buildLanguageSelector(),

            const SizedBox(height: 32),

            // Account actions
            Text(
              'Account acties',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Change password button
            ListTile(
              leading: const Icon(Icons.lock, color: AppColors.mediumBrown),
              title: const Text('Wachtwoord wijzigen'),
              subtitle:
                  const Text('Wijzig je wachtwoord voor extra beveiliging'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _navigateToChangePassword,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.lightGrey),
              ),
            ),

            const SizedBox(height: 12),

            // Delete account button
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: const Text('Account verwijderen'),
              subtitle: const Text('Permanent verwijderen van je account'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _navigateToDeleteAccount,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          // Profile photo
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.lightBrown,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : _currentAvatarUrl != null
                        ? NetworkImage(_currentAvatarUrl!)
                        : null,
                child: _selectedImage == null && _currentAvatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.mediumBrown,
                      )
                    : null,
              ),

              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.mediumBrown,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: AppColors.white),
                    onPressed: _showPhotoOptions,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Profielfoto',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            'Kies een foto die anderen van je zien',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.mediumBrown),
            title: const Text('Taal'),
            subtitle: Text(_getLanguageName(_selectedLanguage)),
            trailing: const Icon(Icons.expand_more),
            onTap: _showLanguageSelector,
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
            onPressed: _loadUserProfile,
            child: const Text('Opnieuw proberen'),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerij'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null || _currentAvatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Foto verwijderen'),
                onTap: () {
                  Navigator.of(context).pop();
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kon foto niet selecteren: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _currentAvatarUrl = null;
    });
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taal selecteren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            final isSelected = language['code'] == _selectedLanguage;
            return ListTile(
              leading: Text(
                language['flag']!,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(language['name']!),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.mediumBrown)
                  : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = language['code']!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    final language = _languages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => _languages.first,
    );
    return '${language['flag']} ${language['name']}';
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
        'name': _nameController.text.trim(),
        'language': _selectedLanguage,
      };

      // Upload photo if selected
      String? avatarUrl;
      if (_selectedImage != null) {
        avatarUrl = await ApiService().uploadProfilePhoto(_selectedImage!);
        profileData['avatar_url'] = avatarUrl;
      } else if (_currentAvatarUrl == null) {
        // Photo was removed
        profileData['avatar_url'] = '';
      }

      await ApiService().updateUserProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profiel opgeslagen'),
            backgroundColor: AppColors.success,
          ),
        );

        // Go back to previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kon profiel niet opslaan: $e'),
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

  void _navigateToChangePassword() {
    Navigator.of(context).pushNamed('/guest/change-password');
  }

  void _navigateToDeleteAccount() {
    Navigator.of(context).pushNamed('/guest/delete-account');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
