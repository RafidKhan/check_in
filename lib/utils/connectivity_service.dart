import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'navigation.dart';

class NetworkConnection {
  static NetworkConnection? _instance;
  NetworkConnection._();
  static NetworkConnection get instance => _instance ??= NetworkConnection._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool isInternet = false;
  bool _dialogShown = false;

  /// Initialize and start listening
  Future<void> initialize() async {
    isInternet = await hasInternetConnection();

    if (!isInternet) {
      _showNoInternetDialog(); // 🔥 Show immediately if offline at app start
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasNet = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi);

      if (!hasNet) {
        isInternet = false;
        _showNoInternetDialog();
      } else {
        isInternet = true;
        _hideDialogIfShown();
      }
    });

    await Future.delayed(const Duration(seconds: 1));
  }


  /// Check if internet is available (Wi-Fi or Mobile)
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi);
    } catch (_) {
      return false;
    }
  }

  /// Show dialog when no internet
  void _showNoInternetDialog() {
    if (_dialogShown) return;

    final context = Navigation.globalKey.currentContext;
    if (context == null) return;

    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text("No Internet"),
            content: const Text("Please check your connection."),
            actions: [
              TextButton(
                onPressed: () async {
                  final ok = await hasInternetConnection();
                  if (ok) {
                    Navigator.of(context, rootNavigator: true).pop();
                    _dialogShown = false;
                  }
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hide dialog when connection is restored
  void _hideDialogIfShown() {
    if (_dialogShown) {
      final context = Navigation.globalKey.currentContext;
      if (context != null) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _dialogShown = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
