import 'dart:io';
import 'package:flutter/services.dart';

/// Flutter assets를 로컬 HTTP로 서빙 (Android WebView용).
/// 게임 HTML이 CDN 외에 상대경로 음악 파일을 로드하므로 file:// 대신 HTTP 사용.
class AssetServer {
  static HttpServer? _server;
  static int get port => _server?.port ?? 0;

  static final _mime = {
    'html': 'text/html; charset=utf-8',
    'js':   'application/javascript',
    'mp3':  'audio/mpeg',
    'png':  'image/png',
    'jpg':  'image/jpeg',
    'css':  'text/css',
    'json': 'application/json',
  };

  static Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handle);
  }

  static void stop() {
    _server?.close(force: true);
    _server = null;
  }

  static Future<void> _handle(HttpRequest req) async {
    // URL: /game/index.html, /game/music/map1.mp3, /main.mp3 등
    final path = req.uri.path.replaceAll(RegExp(r'^/+'), '');
    // Flutter asset path: web/game/index.html, web/game/music/map1.mp3, main.mp3
    final assetPath = path.startsWith('game/') ? 'web/$path'
        : path == 'main.mp3' ? 'main.mp3'
        : path;
    try {
      final data = await rootBundle.load(assetPath);
      final ext = assetPath.split('.').last.toLowerCase();
      req.response
        ..statusCode = 200
        ..headers.set('Content-Type', _mime[ext] ?? 'application/octet-stream')
        ..headers.set('Access-Control-Allow-Origin', '*')
        ..add(data.buffer.asUint8List())
        ..close();
    } catch (_) {
      req.response
        ..statusCode = 404
        ..close();
    }
  }
}
