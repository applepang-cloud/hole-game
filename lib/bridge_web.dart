// Web-only bridge: dart:js_interop → window.holeXxx JS functions
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('holeShowGame') external void _jsShow(JSString m);
@JS('holeHideGame') external void _jsHide();
@JS('holeRestart') external void _jsRestart(JSString m);
@JS('holeInput') external void _jsInput(double x, double y);
@JS('holeToggle') external void _jsToggle(JSString w);
@JS('holePause') external void _jsPause();
@JS('holeResume') external void _jsResume();
@JS('holeMenuMusic') external void _jsMenuMusic(JSBoolean on);
@JS('holeBubbleSfx') external void _jsBubbleSfx();
@JS('holeSpeak') external void _jsSpeak(JSString t, double p);
@JS('holeStopSpeak') external void _jsStopSpeak();
@JS('holeSetSensitivity') external void _jsSetSens(double v);
@JS('holeGetCleared') external JSString _jsGetCleared();
@JS('holeSetCleared') external void _jsSetCleared(JSString s);

void holeShowGame(String mode) => _jsShow(mode.toJS);
void holeHideGame() => _jsHide();
void holeRestart(String mode) => _jsRestart(mode.toJS);
void holeInput(double x, double y) => _jsInput(x, y);
void holeToggle(String what) => _jsToggle(what.toJS);
void holePause() => _jsPause();
void holeResume() => _jsResume();
void holeMenuMusic(bool on) => _jsMenuMusic(on.toJS);
void holeBubbleSfx() { try { _jsBubbleSfx(); } catch (_) {} }
void holeSpeak(String text, double pitch) { try { _jsSpeak(text.toJS, pitch); } catch (_) {} }
void holeStopSpeak() { try { _jsStopSpeak(); } catch (_) {} }
void holeSetSensitivity(double v) => _jsSetSens(v);
String holeGetCleared() { try { return _jsGetCleared().toDart; } catch (_) { return ''; } }
void holeSetCleared(String s) { try { _jsSetCleared(s.toJS); } catch (_) {} }

void registerOnGameMsg(void Function(String) callback) {
  globalContext['__holeOnGameMsg'] = ((JSString json) {
    callback(json.toDart);
  }).toJS;
}
