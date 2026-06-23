import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'asset_server.dart';
import 'bridge_stub.dart' as bridge;

/// Android용 게임 WebView 위젯.
/// [visible]=true일 때 화면에 표시. false면 Offstage로 숨김(상태 유지).
class GameWebView extends StatefulWidget {
  final bool visible;
  final void Function(String json) onMessage;

  const GameWebView({
    super.key,
    required this.visible,
    required this.onMessage,
  });

  @override
  State<GameWebView> createState() => _GameWebViewState();
}

class _GameWebViewState extends State<GameWebView> {
  WebViewController? _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AssetServer.start();
    late final WebViewController ctrl;
    ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'HoleGame',
        onMessageReceived: (msg) => widget.onMessage(msg.message),
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          ctrl.runJavaScript(
            "window.__holeOnGameMsg = function(s){ HoleGame.postMessage(s); };",
          );
        },
      ))
      ..loadRequest(Uri.parse(
          'http://127.0.0.1:${AssetServer.port}/game/index.html'));

    bridge.setWebViewCtrl(ctrl);
    if (mounted) setState(() { _ctrl = ctrl; _initialized = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _ctrl == null) return const SizedBox.shrink();
    return Offstage(
      offstage: !widget.visible,
      child: WebViewWidget(controller: _ctrl!),
    );
  }
}
