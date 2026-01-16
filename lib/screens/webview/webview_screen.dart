import 'package:flutter/material.dart';

class WebViewScreen extends StatelessWidget {
  final String linkType;

  const WebViewScreen({super.key, required this.linkType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView: $linkType'),
      ),
      body: Center(
        child: Text('WebView Screen for: $linkType'),
      ),
    );
  }
}