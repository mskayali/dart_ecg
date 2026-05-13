/// Signal phase computation.
///
/// Port of neurokit2.signal_phase.

/// Compute phase completion of a binary phase signal.
///
/// Given a signal with 0s and 1s (e.g., systole/diastole markers),
/// compute the percentage completion within each phase.
///
/// [signal] — input phase signal (0s and 1s, may have NaN).
/// [method] — 'percent' (default).
List<double> signalPhase(List<double> signal, {String method = 'percent'}) {
  final n = signal.length;
  final result = List<double>.filled(n, double.nan);

  if (method == 'percent') {
    // Find phase transitions
    var currentPhase = double.nan;


    for (var i = 0; i < n; i++) {
      if (!signal[i].isNaN && signal[i] != currentPhase) {
        // Find next transition
        var nextTransition = n;
        for (var j = i + 1; j < n; j++) {
          if (!signal[j].isNaN && signal[j] != signal[i]) {
            nextTransition = j;
            break;
          }
        }

        final phaseLen = nextTransition - i;
        if (phaseLen > 0) {
          for (var j = i; j < nextTransition && j < n; j++) {
            result[j] = (j - i) / phaseLen;
          }
        }

        currentPhase = signal[i];
        i = nextTransition - 1; // Will be incremented by loop
      }
    }
  }

  return result;
}
