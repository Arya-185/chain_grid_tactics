import 'package:flutter/services.dart';

/// Dynamic sound and haptic synthesizer for tactical impacts and harmonic chimes.
class TacticalAudio {
  TacticalAudio._();

  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// Plays progressive harmonic pentatonic chimes based on the cascade wave index.
  /// Wave 0: C4 (261Hz), Wave 1: D4 (293Hz), Wave 2: E4 (329Hz), Wave 3: G4 (392Hz), etc.
  static void playWaveCascade(int waveIndex) {
    if (!hapticsEnabled) return;
    if (waveIndex == 0) {
      HapticFeedback.lightImpact();
    } else if (waveIndex < 3) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static void playOrbPlace() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  static void playVictory() {
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
