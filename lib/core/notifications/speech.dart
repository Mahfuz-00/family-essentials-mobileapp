import 'package:flutter_tts/flutter_tts.dart';

/// Speaks an arrival when the member chose the `voice` style.
///
/// Only possible while the app is running: iOS cannot synthesise speech from a
/// push, and neither platform can speak from a notification the system posted
/// while the app was closed.
class Speech {
  Speech(this._tts);

  final FlutterTts _tts;

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    try {
      await _tts.stop();
      // No language is forced: the device default is the member's own.
      await _tts.speak(text);
    } catch (_) {
      // A missing TTS engine must never break the notification itself.
    }
  }
}
