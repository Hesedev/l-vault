// lib/features/bookmarks/pages/webview_page.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String? title;

  const WebViewPage({super.key, required this.url, this.title});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (_) async {
            if (mounted) {
              setState(() {
                _loadingProgress = 0;
              });
            }
          },
          onPageFinished: (url) async {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _loadingProgress = 100;
              });
              _updateNavState();
            }
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loadingProgress = 100);
          },
        ),
      )
      ..loadRequest(Uri.parse(_ensureScheme(widget.url)));
  }

  Future<void> _updateNavState() async {
    final back = await _controller.canGoBack();
    final forward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = back;
        _canGoForward = forward;
      });
    }
  }

  String _ensureScheme(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }

  String _displayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = _loadingProgress < 100;

    return Scaffold(
      appBar: AppBar(
        // Show title if available, otherwise show the hostname
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null && widget.title!.isNotEmpty)
              Text(
                widget.title!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              _displayUrl(_currentUrl),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.transparent,
                  color: theme.colorScheme.primary,
                  minHeight: 2,
                ),
              )
            : null,
      ),

      body: WebViewWidget(controller: _controller),

      // Bottom navigation bar — back / forward / open in browser
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 48,
          color: theme.scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                onPressed: _canGoBack
                    ? () async {
                        await _controller.goBack();
                        _updateNavState();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                onPressed: _canGoForward
                    ? () async {
                        await _controller.goForward();
                        _updateNavState();
                      }
                    : null,
              ),
              // Divider
              Container(width: 1, height: 24, color: theme.dividerColor),
              // Open externally
              IconButton(
                icon: const Icon(Icons.open_in_browser_rounded, size: 22),
                tooltip: 'Open in browser',
                onPressed: () async {
                  // Using url_launcher is optional; this just copies the URL
                  // for now. If url_launcher is added, replace with launchUrl.
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(_currentUrl),
                      action: SnackBarAction(
                        label: 'Copy',
                        onPressed: () {
                          // Optionally use flutter/services Clipboard
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
