import 'dart:js_interop';

@JS('playSearchWarsNote')
external void _jsPlayNote(JSNumber freq, JSNumber dur, JSString type);

void playWebAudio(double freq, double dur, String type) {
  try {
    _jsPlayNote(freq.toJS, dur.toJS, type.toJS);
  } catch (_) {}
}
