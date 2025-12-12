import 'dart:io';

import 'package:az_incident_alert/utils/app_router.dart';
import 'package:az_incident_alert/utils/shared_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  const TermsAcceptanceScreen({super.key});

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  bool _agreedToTerms = false;
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );

    // Load HTML from assets
    final htmlContent = await rootBundle.loadString(
      'assets/documents/terms_and_conditions.html',
    );

    await _controller.loadHtmlString(htmlContent);
  }

  Future<void> _acceptTerms() async {
    await SharedPrefs.instance.setTermsAccepted(true);

    if (mounted) {
      // Navigate to subscription screen or home
      context.goNamed(AppRoute.subscriptionScreen.name);
    }
  }

  void _declineTerms() {
    // Show dialog confirming exit
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text(
          'You must accept the Terms and Conditions to use Cactus Alert. Exit the app?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (Platform.isAndroid) {
                SystemNavigator.pop();
              } else {
                exit(0);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: const Color(0xFFE8833A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // WebView showing terms
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE8833A),
                    ),
                  ),
              ],
            ),
          ),

          // Agreement checkbox and buttons
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox
                  InkWell(
                    onTap: () {
                      setState(() {
                        _agreedToTerms = !_agreedToTerms;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF7B9337),
                        ),
                        const Expanded(
                          child: Text(
                            'I have read and agree to the Terms and Conditions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      // Decline button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _declineTerms,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Accept button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _agreedToTerms ? _acceptTerms : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8833A),
                            disabledBackgroundColor: Colors.grey[300],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Accept and Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
