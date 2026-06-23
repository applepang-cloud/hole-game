// 웹 빌드용 GameWebView 스텁 — 웹은 iframe으로 게임을 표시하므로 WebView 불필요.
import 'package:flutter/material.dart';

class GameWebView extends StatelessWidget {
  final bool visible;
  final void Function(String json) onMessage;
  const GameWebView({super.key, required this.visible, required this.onMessage});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
