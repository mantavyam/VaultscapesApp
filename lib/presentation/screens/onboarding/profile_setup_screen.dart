import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../../core/constants/route_constants.dart';
import '../../../data/services/firestore_service.dart';

/// Profile setup screen for first-time authenticated users
/// Allows users to customize their display name and select gender
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late TextEditingController _nameController;
  String? _selectedGender;
  bool _isLoading = false;
  int _currentStep = 0; // 0 = name, 1 = gender

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameController.addListener(() {
      setState(() {}); // Rebuild on text change for character count
    });
    // Pre-fill with user's name from auth provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userName = authProvider.user?.displayName ?? '';
      _nameController.text = userName;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(theme),
              const SizedBox(height: 32),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0
                      ? _buildNameStep(theme)
                      : _buildGenderStep(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, theme),
        Container(
          width: 40,
          height: 2,
          color: _currentStep >= 1
              ? theme.colorScheme.primary
              : theme.colorScheme.muted,
        ),
        _buildStepDot(1, theme),
      ],
    );
  }

  Widget _buildStepDot(int step, ThemeData theme) {
    final isActive = _currentStep >= step;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.muted,
      ),
    );
  }

  Widget _buildNameStep(ThemeData theme) {
    return Column(
      key: const ValueKey('name_step'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          "We'll call you",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can change this anytime',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 32),

        // Name input field using shadcn TextField
        SizedBox(
          width: double.infinity,
          child: TextField(
            controller: _nameController,
            placeholder: const Text('Enter your name'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),

        // Character count hint
        Text(
          '${_nameController.text.length}/30 characters',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.mutedForeground,
          ),
        ),

        const Spacer(),

        // Continue button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: PrimaryButton(
            onPressed: _nameController.text.trim().isNotEmpty
                ? _goToGenderStep
                : null,
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderStep(ThemeData theme) {
    return Column(
      key: const ValueKey('gender_step'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.wc_rounded,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          "You're a",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.foreground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us personalize your experience',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 48),

        // Gender selection cards
        Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                theme,
                gender: 'male',
                icon: Icons.male_rounded,
                label: 'Male',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderCard(
                theme,
                gender: 'female',
                icon: Icons.female_rounded,
                label: 'Female',
              ),
            ),
          ],
        ),

        const Spacer(),

        // Navigation buttons
        Row(
          children: [
            // Back button
            OutlineButton(
              onPressed: _goBackToNameStep,
              child: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 16),
            // Continue button
            Expanded(
              child: SizedBox(
                height: 48,
                child: PrimaryButton(
                  onPressed: _selectedGender != null && !_isLoading
                      ? _completeSetup
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Let's Go!"),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(
    ThemeData theme, {
    required String gender,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToGenderStep() {
    if (_nameController.text.trim().isEmpty) return;
    setState(() {
      _currentStep = 1;
    });
  }

  void _goBackToNameStep() {
    setState(() {
      _currentStep = 0;
    });
  }

  Future<void> _completeSetup() async {
    if (_selectedGender == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final onboardingProvider = context.read<OnboardingProvider>();
      final user = authProvider.user;

      // Update display name if changed
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty && newName != authProvider.user?.displayName) {
        await authProvider.updateDisplayName(newName);
      }

      // Store user data in Firestore (name, gender, etc.)
      if (user != null) {
        final firestoreService = FirestoreService();
        await firestoreService.createOrUpdateUser(
          uid: user.uid,
          displayName: newName.isNotEmpty
              ? newName
              : (user.displayName ?? 'User'),
          email: user.email ?? '',
          photoUrl: user.photoUrl,
          gender: _selectedGender,
          provider: user.provider,
          merge: true,
        );
      }

      // Complete profile setup
      await onboardingProvider.completeProfileSetup(gender: _selectedGender!);

      // Navigate to home
      if (mounted) {
        context.go(RouteConstants.home);
      }
    } catch (e) {
      if (mounted) {
        // Show error using showToast from shadcn_flutter
        showToast(
          context: context,
          builder: (context, overlay) {
            return SurfaceCard(
              child: Basic(
                title: const Text('Error'),
                subtitle: Text('Failed to complete setup: $e'),
                trailing: IconButton.ghost(
                  icon: const Icon(Icons.close),
                  onPressed: () => overlay.close(),
                ),
              ),
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
