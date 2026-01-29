import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../core/responsive/responsive.dart';

/// Custom bottom navigation bar using shadcn_flutter styling
/// Adapts to viewport size: icons only in micro viewports, full labels in larger viewports
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final windowSize = ResponsiveLayout.getWindowSize(context);
    
    // Adaptive padding based on viewport
    final horizontalPadding = windowSize.isMicro ? 4.0 : 8.0;
    final verticalPadding = windowSize.isMicro ? 6.0 : 8.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
                windowSize: windowSize,
              ),
              _NavItem(
                icon: Icons.psychology_rounded,
                label: 'Breakthrough',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
                windowSize: windowSize,
              ),
              _NavItem(
                icon: Icons.bolt,
                label: 'Synergy',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
                windowSize: windowSize,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
                windowSize: windowSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final WindowSize windowSize;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.windowSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.mutedForeground;

    // Adaptive sizing based on viewport
    final iconSize = windowSize.isMicro ? 20.0 : 24.0;
    final showLabels = ResponsiveLayout.shouldShowNavigationLabels(context);
    final minTouchTarget = ResponsiveLayout.getMinTouchTarget(context);
    
    // Adaptive padding
    final horizontalPadding = isSelected
        ? (windowSize.isMicro ? 12.0 : 16.0)
        : (windowSize.isMicro ? 8.0 : 12.0);
    final verticalPadding = windowSize.isMicro ? 6.0 : 8.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minTouchTarget,
          minHeight: minTouchTarget,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(windowSize.isMicro ? 10 : 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: iconSize,
              ),
              // Only show label when selected AND viewport allows labels
              if (isSelected && showLabels) ...[
                SizedBox(width: windowSize.isMicro ? 6 : 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: windowSize.isMicro ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
