import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
class RdioscannerScreen extends StatefulWidget {
  const RdioscannerScreen({super.key});

  @override
  State<RdioscannerScreen> createState() => _RdioscannerScreenState();
}

class _RdioscannerScreenState extends State<RdioscannerScreen> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isCheckingConnection = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isWebViewInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    debugPrint('🗑️ RdioscannerScreen disposing...');
    // Stop audio immediately before dispose
    if (_isWebViewInitialized && !_hasError) {
      try {
        // Clear cache and load blank page
        _controller.clearCache();
        _controller.loadRequest(Uri.parse('about:blank'));
      } catch (e) {
        debugPrint('Error in dispose: $e');
      }
    }
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopAudioPlayback();
    }
  }

  Future<void> _stopAudioPlayback() async {
    debugPrint('🔇 Attempting to stop audio playback...');
    if (_isWebViewInitialized && !_hasError) {
      try {
        // Step 1: Run JavaScript to stop audio in main page and ALL iframes
        debugPrint('🔇 Step 1: Running JavaScript to stop all audio...');
        await _controller.runJavaScript('''
          (function() {
            try {
              console.log('Stopping audio in main page and iframes...');

              // Function to stop audio in a document
              function stopAudioInDocument(doc) {
                try {
                  // Stop all audio elements
                  doc.querySelectorAll('audio').forEach(function(audio) {
                    console.log('Pausing audio element:', audio);
                    audio.pause();
                    audio.currentTime = 0;
                    audio.src = '';
                    audio.load();
                  });

                  // Stop all video elements
                  doc.querySelectorAll('video').forEach(function(video) {
                    console.log('Pausing video element:', video);
                    video.pause();
                    video.currentTime = 0;
                    video.src = '';
                    video.load();
                  });

                  // Click any active play/stop buttons
                  doc.querySelectorAll('button').forEach(function(btn) {
                    var btnText = btn.textContent.toLowerCase();
                    var btnClass = btn.className.toLowerCase();
                    if (btnText.includes('stop') || btnText.includes('pause') ||
                        btnClass.includes('stop') || btnClass.includes('pause') ||
                        btnClass.includes('playing') || btnClass.includes('active')) {
                      console.log('Clicking button:', btn);
                      btn.click();
                    }
                  });
                } catch(err) {
                  console.log('Error stopping audio in document:', err);
                }
              }

              // Stop in main document
              stopAudioInDocument(document);

              // Stop in all iframes
              document.querySelectorAll('iframe').forEach(function(iframe) {
                try {
                  console.log('Stopping audio in iframe:', iframe);
                  stopAudioInDocument(iframe.contentDocument || iframe.contentWindow.document);
                } catch(err) {
                  console.log('Cannot access iframe (cross-origin):', err);
                }
              });

              // Stop Web Audio API
              if (window.AudioContext || window.webkitAudioContext) {
                console.log('Closing AudioContext...');
                if (window.audioContext) {
                  window.audioContext.close();
                }
              }

              // Stop media session
              if (navigator.mediaSession) {
                console.log('Stopping media session...');
                navigator.mediaSession.playbackState = 'none';
              }

              console.log('Audio stop complete');
            } catch(err) {
              console.log('Error in stopAudioPlayback:', err);
            }
          })();
        ''');

        await Future.delayed(const Duration(milliseconds: 300));

        // Step 2: Clear cache
        debugPrint('🔇 Step 2: Clearing cache...');
        await _controller.clearCache();

        await Future.delayed(const Duration(milliseconds: 100));

        // Step 3: Load blank page
        debugPrint('🔇 Step 3: Loading blank page...');
        await _controller.loadRequest(Uri.parse('about:blank'));

       await Future.delayed(const Duration(milliseconds: 500));

        debugPrint('🔇 Audio should be stopped now');
      } catch (e) {
        debugPrint('❌ Error stopping audio playback: $e');
        // Even if JavaScript fails, try to load blank page
        try {
          await _controller.loadRequest(Uri.parse('about:blank'));
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e2) {
          debugPrint('❌ Error loading blank page: $e2');
        }
      }
    } else {
      debugPrint('⚠️ WebView not initialized or has error, skipping audio stop');
    }
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
              _isWebViewInitialized = true;
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

  Future<bool> _handleBackPress() async {
    debugPrint('⬅️ Back button pressed (handler)');
    await _stopAudioPlayback();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        debugPrint('⬅️ PopScope onPopInvoked called, didPop: $didPop');
        if (didPop) return;
        await _stopAudioPlayback();
        if (context.mounted) {
          debugPrint('✅ Navigating back after stopping audio');
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Radio Scanner'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              debugPrint('⬅️ AppBar back button clicked');
              await _stopAudioPlayback();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
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
      ),
    );
  }
}

