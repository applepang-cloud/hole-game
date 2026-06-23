// 플랫폼 조건부 bridge export.
// 웹: bridge_web.dart (dart:js_interop)
// Android/기타: bridge_stub.dart (WebView + no-op stubs)
export 'bridge_web.dart' if (dart.library.io) 'bridge_stub.dart';
