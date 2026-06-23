// Android/non-web bridge stubs.
// Game communication happens via WebViewController.runJavaScript() — see game_webview.dart.
import 'package:webview_flutter/webview_flutter.dart';

WebViewController? _ctrl;
void Function(String)? _onMsg;

/// Android에서 WebViewController를 등록. game_webview.dart가 호출.
void setWebViewCtrl(WebViewController c) => _ctrl = c;

/// game_webview.dart의 JavascriptChannel 수신 시 호출.
void dispatchGameMsg(String json) => _onMsg?.call(json);

void holeShowGame(String mode) =>
    _ctrl?.runJavaScript("window.__holeEngine?.start('$mode')");
void holeHideGame() =>
    _ctrl?.runJavaScript("window.__holeEngine?.stop()");
void holeRestart(String mode) =>
    _ctrl?.runJavaScript("window.__holeEngine?.start('$mode')");
void holeInput(double x, double y) =>
    _ctrl?.runJavaScript("window.__holeEngine?.input($x,$y)");
void holeToggle(String what) =>
    _ctrl?.runJavaScript("window.__holeEngine?.toggle${what[0].toUpperCase()}${what.substring(1)}()");
void holePause() =>
    _ctrl?.runJavaScript("window.__holeEngine?.pause()");
void holeResume() =>
    _ctrl?.runJavaScript("window.__holeEngine?.resume()");
void holeMenuMusic(bool on) {} // 메뉴 BGM — Android에선 no-op (WebAudio 별도)
void holeBubbleSfx() {}        // 블립음 — Android no-op
void holeSpeak(String text, double pitch) {} // TTS — Android no-op (향후 flutter_tts 연결)
void holeStopSpeak() {}
void holeSetSensitivity(double v) =>
    _ctrl?.runJavaScript("window.__holeEngine?.setSensitivity($v)");
String holeGetCleared() => ''; // 로컬스토리지 미사용 — 향후 SharedPreferences로 대체
void holeSetCleared(String s) {}

void registerOnGameMsg(void Function(String) callback) {
  _onMsg = callback;
}
