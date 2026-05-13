/// ECG cardiac phase computation.
///
/// Port of neurokit2.ecg_phase.

/// Compute cardiac phase.
///
/// Returns (atrial, ventricular) phase signals.
({List<double> atrial, List<double> ventricular}) ecgPhase(
  List<int> rpeaks, {
  List<int>? tOffsets,
  List<int>? pOnsets,
  required int signalLength,
}) {
  final atrial = List<double>.filled(signalLength, double.nan);
  final ventricular = List<double>.filled(signalLength, double.nan);
  if (rpeaks.isEmpty) return (atrial: atrial, ventricular: ventricular);

  for (var i = 0; i < rpeaks.length; i++) {
    final rpeak = rpeaks[i];
    final nextRpeak = i < rpeaks.length - 1 ? rpeaks[i + 1] : signalLength;
    final rrInterval = nextRpeak - rpeak;
    final systoleEnd = rpeak + (0.4 * rrInterval).round();

    for (var j = rpeak; j < systoleEnd && j < signalLength; j++) {
      ventricular[j] = 0.0;
    }
    for (var j = systoleEnd; j < nextRpeak && j < signalLength; j++) {
      ventricular[j] = 1.0;
    }
  }

  if (pOnsets != null && tOffsets != null) {
    for (var i = 0; i < signalLength; i++) {
      atrial[i] = 0.0;
    }
    for (var i = 0; i < pOnsets.length; i++) {
      final pOnset = pOnsets[i];
      final tOffset = i < tOffsets.length ? tOffsets[i] : -1;
      if (tOffset >= 0 && tOffset < signalLength) {
        for (var j = pOnset; j <= tOffset && j < signalLength; j++) {
          atrial[j] = 1.0;
        }
      }
    }
  }

  return (atrial: atrial, ventricular: ventricular);
}
