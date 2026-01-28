### Technical Guidelines for Implementing a Global Connectivity Banner in Flutter

This feature requires a **global, non-overlay banner** that **integrates into the layout** (pushes content down instead of floating over it), dynamically adjusts screen space, and reflects real-time internet connectivity status exactly like the Pinterest implementation shown in the screenshots.

#### Core Requirements Recap
- Banner appears at the very top of the screen (above any persistent search bar or app bar).
- It **pushes all content downward** when visible (dynamic layout squeeze).
- Two states:
  - **Online (reconnected)**: "You're back online." with `LucideIcons.radioTower`, faded light green background. Shown temporarily (3–5 seconds), then fully hidden with animation.
  - **Offline**: "You're offline. Please check your Internet connection." with `LucideIcons.cloudOff`, faded light red/pink background. Persists until connection returns.
- Global: Visible on every screen, regardless of navigation.

#### Key Vocabulary & Concepts
- **Non-overlay banner**: Banner is part of the normal widget tree (not `OverlayEntry`, `SnackBar`, or `Stack` positioned widget). Achieved via `Column` layout.
- **Dynamic layout squeeze / content push**: Banner insertion animates height change, forcing `Expanded`/`Flexible` children below to resize smoothly.
- **Animated insertion/removal**: Smooth slide-in/slide-out + fade using height animation (`SizeTransition`, `AnimatedContainer`, or `TweenAnimationBuilder`).
- **Global state**: Managed via a top-level provider (Provider/Riverpod/Bloc) so any screen can react without duplication.
- **Transient vs persistent display**: Online banner auto-hides with `Timer`; offline banner stays until state changes.

#### Required Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  connectivity_plus: ^6.0.0   # For real-time connectivity monitoring
  provider: ^6.1.1            # Simple state management (alternatives: riverpod, bloc)
  lucide_icons: ^0.0.1        # Or your Lucide icon package
```

#### Step-by-Step Implementation Approach

1. **Connectivity State Management**
Create a `ChangeNotifier` to track status and control banner visibility.

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _showBanner = false;
  String _message = '';
  IconData _icon = Icons.wifi;
  Color _bgColor = Colors.transparent;
  Timer? _hideTimer;

  ConnectivityProvider() {
    // Initial check
    _checkInitial();
    // Listen to changes
    Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        _setOffline();
      } else {
        _setOnline();
      }
    });
  }

  void _checkInitial() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    // Do not show "back online" banner on app launch
    notifyListeners();
  }

  void _setOffline() {
    _isOnline = false;
    _showBanner = true;
    _message = "You're offline. Please check your Internet connection.";
    _icon = LucideIcons.cloudOff;
    _bgColor = const Color(0xFFFFEBEE); // Faded light red/pink
    _hideTimer?.cancel();
    notifyListeners();
  }

  void _setOnline() {
    if (!_isOnline) {
      _isOnline = true;
      _showBanner = true;
      _message = "You're back online.";
      _icon = LucideIcons.radioTower;
      _bgColor = const Color(0xFFE8F5E9); // Faded light green
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 4), () {
        _showBanner = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  bool get showBanner => _showBanner;
  String get message => _message;
  IconData get icon => _icon;
  Color get bgColor => _bgColor;
}
```

2. **Connectivity Banner Widget (Animated Insertion)**
Use `TweenAnimationBuilder` + `SizeTransition` for smooth slide-down/push effect (best match for Pinterest's feel).

```dart
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
              child: Container(
                width: double.infinity,
                color: provider.bgColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(provider.icon, size: 20, color: provider._isOnline ? Colors.green[800] : Colors.red[800]),
                    const SizedBox(width: 8),
                    Text(
                      provider.message,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
```

3. **Global Layout Integration (Root-Level Wrapper)**
Wrap your main content in a `Column` so the banner pushes everything down.

```dart
class MainAppBody extends StatelessWidget {
  final Widget child; // Your page content or navigator

  const MainAppBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const ConnectivityBanner(),        // Pushes content down
          // Your persistent search bar here if you have one (like Pinterest)
          // const PinterestSearchBar(),
          Expanded(child: child),            // All page content
        ],
      ),
    );
  }
}
```

In `MaterialApp` or root:

```dart
ChangeNotifierProvider(
  create: (_) => ConnectivityProvider(),
  child: MaterialApp(
    home: Scaffold(
      body: MainAppBody(child: YourHomePageOrNavigator()),
      bottomNavigationBar: YourBottomNavBar(),
    ),
  ),
)
```

#### Styling Notes (Match Pinterest Screenshots)
- Background: 
  - Online: `Color(0xFFE8F5E9)` or `Colors.green[100]`
  - Offline: `Color(0xFFFFEBEE)` or `Colors.red[50]`
- Height: ~48–56 logical pixels
- Text: Centered row, medium weight, dark color for readability
- Icon: Small (20–24), tinted darker green/red
- Padding: Vertical 12, horizontal auto (centered)

#### Advantages of This Approach
- True **non-overlay** behavior (content is physically displaced).
- Smooth **animated squeeze** matching Pinterest.
- Minimal performance impact.
- Works across navigation (single source of truth via provider).

This implementation will behave identically to the Pinterest screenshots: banner integrates seamlessly, pushes the search bar/content down, animates in/out, and disappears completely when not needed.