import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to check and monitor internet connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isConnected = true;
  final _controller = StreamController<bool>.broadcast();
  
  /// Get connectivity status stream
  Stream<bool> get connectivityStream => _controller.stream;
  
  /// Get current connectivity status
  bool get isConnected => _isConnected;
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isConnected = !result.contains(ConnectivityResult.none);
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasConnected = _isConnected;
        _isConnected = !results.contains(ConnectivityResult.none);
        
        if (wasConnected != _isConnected) {
          debugPrint('ConnectivityService: Connection status changed to: $_isConnected');
          _controller.add(_isConnected);
        }
      },
    );
  }
  
  /// Check if device is currently connected to internet
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = !result.contains(ConnectivityResult.none);
      return _isConnected;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity: $e');
      return false;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.close();
  }
}
