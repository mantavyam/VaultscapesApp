import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Edit profile dialog
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(
      text: authProvider.user?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Display Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            enabled: !_isLoading,
          ),
        ],
      ),
      actions: [
        OutlineButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        PrimaryButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  void _saveProfile() async {
    if (_nameController.text.isEmpty) {
      showToast(
        context: context,
        builder: (context, overlay) {
          return SurfaceCard(
            child: Basic(
              title: const Text('Name cannot be empty'),
              leading: Icon(Icons.warning, color: Theme.of(context).colorScheme.destructive),
              trailing: IconButton.ghost(
                icon: const Icon(Icons.close),
                onPressed: () => overlay.close(),
              ),
            ),
          );
        },
        location: ToastLocation.bottomCenter,
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateDisplayName(_nameController.text);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pop();
        showToast(
          context: context,
          builder: (context, overlay) {
            return SurfaceCard(
              child: Basic(
                title: const Text('Profile updated successfully'),
                leading: Icon(Icons.check_circle, color: Colors.green),
                trailing: IconButton.ghost(
                  icon: const Icon(Icons.close),
                  onPressed: () => overlay.close(),
                ),
              ),
            );
          },
          location: ToastLocation.bottomCenter,
        );
      } else {
        showToast(
          context: context,
          builder: (context, overlay) {
            return SurfaceCard(
              child: Basic(
                title: const Text('Failed to update profile'),
                leading: Icon(Icons.error, color: Theme.of(context).colorScheme.destructive),
                trailing: IconButton.ghost(
                  icon: const Icon(Icons.close),
                  onPressed: () => overlay.close(),
                ),
              ),
            );
          },
          location: ToastLocation.bottomCenter,
        );
      }
    }
  }
}
