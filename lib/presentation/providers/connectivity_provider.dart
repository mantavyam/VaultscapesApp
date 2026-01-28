import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/connectivity_service.dart';

/// Provider to manage connectivity state globally and control banner visibility.
/// Implements the Pinterest-style banner behavior:
/// - Offline: Persistent red/pink banner until connection returns
/// - Online (reconnected): Temporary green banner that auto-hides after 4 seconds
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _subscription;
  Timer? _hideTimer;

  bool _isOnline = true;
  bool _showBanner = false;
  bool _wasOffline =
      false; // Track if we were offline to know when to show "back online"

  ConnectivityProvider({ConnectivityService? connectivityService})
    : _connectivityService = connectivityService ?? ConnectivityService() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize the connectivity service
    await _connectivityService.initialize();

    // Get initial state
    _isOnline = _connectivityService.isConnected;

    // If initially offline, show the offline banner
    if (!_isOnline) {
      _setOffline();
    }

    // Listen to connectivity changes
    _subscription = _connectivityService.connectivityStream.listen((
      isConnected,
    ) {
      if (isConnected) {
        _setOnline();
      } else {
        _setOffline();
      }
    });
  }

  void _setOffline() {
    _wasOffline = true;
    _isOnline = false;
    _showBanner = true;
    _hideTimer?.cancel();
    notifyListeners();
  }

  void _setOnline() {
    final wasOfflineBefore = _wasOffline;
    _isOnline = true;

    // Only show "back online" banner if we were previously offline
    if (wasOfflineBefore) {
      _showBanner = true;
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 4), () {
        _showBanner = false;
        _wasOffline = false; // Reset the flag after showing "back online"
        notifyListeners();
      });
    }
    notifyListeners();
  }

  /// Whether the device is currently online
  bool get isOnline => _isOnline;

  /// Whether to show the connectivity banner
  bool get showBanner => _showBanner;

  /// Check connectivity manually
  Future<bool> checkConnectivity() async {
    return await _connectivityService.checkConnectivity();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }
}
