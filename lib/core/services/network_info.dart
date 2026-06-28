import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }
}

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.isOnline, required this.child});

  final bool isOnline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOnline ? 0 : 28,
          color: Colors.orange.shade800,
          child: isOnline
              ? null
              : const Center(
                  child: Text(
                    'You are offline. Changes will sync when connected.',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
