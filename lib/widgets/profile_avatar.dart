import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoURL;
  final String initials;
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.photoURL,
    required this.initials,
    this.size = AppSizes.avatarLarge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: _generateBackgroundColor(initials),
        child: photoURL != null
            ? ClipOval(
                child: Image.network(
                  photoURL!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitialsText();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildInitialsText();
                  },
                ),
              )
            : _buildInitialsText(),
      ),
    );
  }

  Widget _buildInitialsText() {
    return Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontSize: _getFontSize(),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  double _getFontSize() {
    if (size >= AppSizes.avatarLarge) {
      return 28;
    } else if (size >= AppSizes.avatarMedium) {
      return 20;
    } else {
      return 16;
    }
  }

  Color _generateBackgroundColor(String text) {
    // Generate a consistent color based on the text
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF795548), // Brown
      const Color(0xFF009688), // Teal
    ];

    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }
}