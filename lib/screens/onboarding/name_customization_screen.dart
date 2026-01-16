import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';

class NameCustomizationScreen extends StatefulWidget {
  const NameCustomizationScreen({super.key});

  @override
  State<NameCustomizationScreen> createState() => _NameCustomizationScreenState();
}

class _NameCustomizationScreenState extends State<NameCustomizationScreen> {
  late TextEditingController _nameController;
  bool _isLoading = false;
  String _characterCount = '0/${AppStrings.nameMaxLength}';

  @override
  void initState() {
    super.initState();
    
    // Initialize with provider name
    final user = context.read<UserProvider>().currentUser;
    _nameController = TextEditingController(text: user?.providerName ?? '');
    _updateCharacterCount();
    
    // Listen to text changes
    _nameController.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = '${_nameController.text.length}/${AppStrings.nameMaxLength}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable back button
        title: const Text('Customize Profile'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // User Avatar Placeholder
                    CircleAvatar(
                      radius: AppSizes.avatarLarge / 2,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: user?.photoURL != null
                          ? ClipOval(
                              child: Image.network(
                                user!.photoURL!,
                                width: AppSizes.avatarLarge,
                                height: AppSizes.avatarLarge,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    user.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Text(
                              user?.initials ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Customize Name Label
                    Text(
                      AppStrings.customizeYourName,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Hint Text
                    Text(
                      AppStrings.nameHintText,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Name TextField
                    TextField(
                      controller: _nameController,
                      maxLength: AppStrings.nameMaxLength,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        counterText: _characterCount,
                        counterStyle: Theme.of(context).textTheme.bodySmall,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Loading indicator
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _continue,
                  child: const Text(AppStrings.continueButton),
                ),
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Skip Button
              TextButton(
                onPressed: _isLoading ? null : _skip,
                child: const Text(AppStrings.skipForNow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue() async {
    final trimmedName = _nameController.text.trim();
    
    // Validate name length
    if (trimmedName.length < AppStrings.nameMinLength) {
      _showError('Name must be at least ${AppStrings.nameMinLength} characters long');
      return;
    }
    
    if (trimmedName.length > AppStrings.nameMaxLength) {
      _showError('Name must be no more than ${AppStrings.nameMaxLength} characters long');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.updateUserName(trimmedName);
      
      if (success && mounted) {
        context.go('/home');
      } else if (mounted) {
        _showError('Failed to update name. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update name. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skip() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = context.read<UserProvider>().currentUser;
      if (user != null) {
        // Set custom name to provider name (effectively skipping customization)
        final userProvider = context.read<UserProvider>();
        await userProvider.updateUserName(user.providerName);
      }
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to proceed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}