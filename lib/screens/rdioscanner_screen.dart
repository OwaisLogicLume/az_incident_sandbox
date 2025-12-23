import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RdioscannerScreen extends StatefulWidget {
  const RdioscannerScreen({super.key});

  @override
  State<RdioscannerScreen> createState() => _RdioscannerScreenState();
}

class _RdioscannerScreenState extends State<RdioscannerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isCheckingConnection = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndLoad();

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi)) {
        if (_hasError) {
          _retryLoad();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivityAndLoad() async {
    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _isCheckingConnection = false;
          _errorMessage = 'No internet connection. Please check your network settings.';
        });
        return;
      }

      setState(() {
        _isCheckingConnection = false;
      });

      _initializeWebView();
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isCheckingConnection = false;
        _errorMessage = 'Error checking connectivity: $e';
      });
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('WebView loading: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            debugPrint('WebView finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error code: ${error.errorCode}');
            debugPrint('WebView error: ${error.description}');
            debugPrint('WebView error type: ${error.errorType}');

            String userFriendlyMessage = error.description;

            if (error.errorCode == -2) {
              userFriendlyMessage = 'No internet connection or unable to reach server.';
            } else if (error.errorCode == -6) {
              userFriendlyMessage = 'Connection failed. Please check your internet.';
            } else if (error.description.toLowerCase().contains('net::')) {
              userFriendlyMessage = 'Network error. Please check your internet connection.';
            }

            setState(() {
              _hasError = true;
              _isLoading = false;
              _errorMessage = userFriendlyMessage;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://rdioscanner.com/'));
  }

  void _retryLoad() {
    _checkConnectivityAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radio Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isCheckingConnection)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _retryLoad(),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (!_hasError && !_isCheckingConnection)
            WebViewWidget(controller: _controller),
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _errorMessage.contains('internet') || _errorMessage.contains('connection')
                          ? Icons.wifi_off
                          : Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load webpage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'URL: https://rdioscanner.com/',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryLoad,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading && !_hasError || _isCheckingConnection)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _isCheckingConnection
                        ? 'Checking internet connection...'
                        : 'Loading radio scanner...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

