import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewAuth extends StatefulWidget {
  const WebViewAuth({super.key});

  @override
  WebViewAuthState createState() => WebViewAuthState();
}

class WebViewAuthState extends State<WebViewAuth> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _authenticated = false;
  late final WebViewController _controller;

  Future<void> _authenticate() async {
    try {
      _authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access the web content',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      print(e);
    }

    if (_authenticated) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
          Uri.parse('https://www.example.com')); // replace with your URL
    _authenticate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView with Fingerprint'),
      ),
      body: _authenticated
          ? WebViewWidget(controller: _controller)
          : const Center(
              child: Text('Authenticating...'),
            ),
    );
  }
}
