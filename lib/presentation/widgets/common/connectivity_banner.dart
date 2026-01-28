import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;
import 'package:provider/provider.dart';
import '../../providers/connectivity_provider.dart';

/// A global connectivity banner that integrates into the layout (pushes content down).
/// Shows two states:
/// - Offline: "You're offline. Please check your Internet connection." with red background, persists until reconnected
/// - Online (reconnected): "You're back online." with green background, auto-hides after 4 seconds
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, provider, _) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          tween: Tween(begin: 0.0, end: provider.showBanner ? 1.0 : 0.0),
          builder: (context, value, child) {
            return SizeTransition(
              sizeFactor: AlwaysStoppedAnimation(value),
              axis: Axis.vertical,
              child: _BannerContent(isOnline: provider.isOnline),
            );
          },
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  final bool isOnline;

  const _BannerContent({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isOnline
        ? const Color(0xFFE8F5E9) // Faded light green
        : const Color(0xFFFFEBEE); // Faded light red/pink

    final iconColor = isOnline
        ? const Color(0xFF2E7D32) // Dark green
        : const Color(0xFFC62828); // Dark red

    final textColor = isOnline
        ? const Color(0xFF1B5E20) // Darker green for text
        : const Color(0xFFB71C1C); // Darker red for text

    final icon = isOnline ? LucideIcons.radioTower : LucideIcons.cloudOff;

    final message = isOnline
        ? "You're back online."
        : "You're offline. Please check your Internet connection.";

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
