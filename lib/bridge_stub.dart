// Android/non-web bridge stubs.
// Game communication happens via WebViewController.runJavaScript() — see game_webview.dart.
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
void holeMenuMusic(bool on) {} // 메뉴 BGM — Android에선 no-op (게임 WebAudio가 담당)
void holeBubbleSfx() {}        // 블립음 — Android no-op (게임 내부 SFX 사용)

// Android 시스템 TTS (한국어) — 대사 컷씬 음성.
FlutterTts? _tts;
bool _ttsReady = false;
FlutterTts _ttsGet() {
  final t = _tts ??= FlutterTts();
  if (!_ttsReady) {
    _ttsReady = true;
    t.setLanguage('ko-KR');
    t.setSpeechRate(0.52); // Android rate 스케일(웹 1.04 대비 자연스러운 속도)
    t.setVolume(0.9);
  }
  return t;
}

void holeSpeak(String text, double pitch) {
  try {
    final t = _ttsGet();
    // 웹 pitch(0.7~1.4) → Android pitch(0.5~2.0) 범위로 클램프
    final p = pitch < 0.5 ? 0.5 : (pitch > 2.0 ? 2.0 : pitch);
    t.setPitch(p);
    t.stop();
    t.speak(text);
  } catch (_) {}
}

void holeStopSpeak() {
  try { _tts?.stop(); } catch (_) {}
}

void holeSetSensitivity(double v) =>
    _ctrl?.runJavaScript("window.__holeEngine?.setSensitivity($v)");
String holeGetCleared() => ''; // 진행도 영속 미사용 — 향후 SharedPreferences로 대체
void holeSetCleared(String s) {}

void registerOnGameMsg(void Function(String) callback) {
  _onMsg = callback;
}
