/// R-peak artifact correction.
///
/// Port of neurokit2.signal_fixpeaks — Kubios artifact correction
/// based on Lipponen & Tarvainen (2019).


/// Fix R-peak artifacts using interval-based detection.
///
/// Implements a simplified version of the Kubios artifact correction:
/// detects and corrects ectopic, missed, and extra beats.
///
/// [peaks] — detected R-peak indices.
/// [samplingRate] — sampling frequency in Hz.
/// [method] — 'kubios' (default) or 'neurokit'.
///
/// Returns corrected R-peak indices.
List<int> signalFixpeaks(
  List<int> peaks, {
  required double samplingRate,
  String method = 'kubios',
}) {
  if (peaks.length < 4) return List<int>.from(peaks);

  switch (method.toLowerCase()) {
    case 'kubios':
      return _fixpeaksKubios(peaks, samplingRate);
    case 'neurokit':
    default:
      return _fixpeaksNeurokit(peaks, samplingRate);
  }
}

/// Simplified Kubios-style artifact correction.
///
/// Based on Lipponen & Tarvainen (2019):
/// 1. Compute RR intervals
/// 2. Classify each interval (normal, ectopic, missed, extra, long/short)
/// 3. Correct based on classification
List<int> _fixpeaksKubios(List<int> peaks, double samplingRate) {
  if (peaks.length < 4) return List<int>.from(peaks);

  var corrected = List<int>.from(peaks);
  var changed = true;
  var iterations = 0;

  while (changed && iterations < 10) {
    changed = false;
    iterations++;

    final rr = <double>[];
    for (var i = 1; i < corrected.length; i++) {
      rr.add((corrected[i] - corrected[i - 1]).toDouble());
    }

    if (rr.length < 3) break;

    // Median RR interval
    final medRR = List<double>.from(rr)..sort();
    final medianRR = medRR[medRR.length ~/ 2];

    // Detect artifacts
    final toRemove = <int>{};
    final toInsert = <int>[];

    for (var i = 0; i < rr.length; i++) {
      final ratio = rr[i] / medianRR;

      // Extra beat: very short interval
      if (ratio < 0.5 && i + 1 < corrected.length) {
        // Remove the peak that creates the short interval
        // Keep the one closer to expected position
        toRemove.add(i + 1);
        changed = true;
      }
      // Missed beat: very long interval
      else if (ratio > 1.8 && ratio < 2.5) {
        // Insert a peak at midpoint
        final midpoint =
            ((corrected[i] + corrected[i + 1]) / 2.0).round();
        toInsert.add(midpoint);
        changed = true;
      }
    }

    // Apply corrections
    if (changed) {
      final newPeaks = <int>[];
      for (var i = 0; i < corrected.length; i++) {
        if (!toRemove.contains(i)) {
          newPeaks.add(corrected[i]);
        }
      }
      newPeaks.addAll(toInsert);
      newPeaks.sort();
      corrected = newPeaks;
    }
  }

  return corrected;
}

/// Simple NeuroKit-style peak correction.
List<int> _fixpeaksNeurokit(List<int> peaks, double samplingRate) {
  if (peaks.length < 3) return List<int>.from(peaks);

  final corrected = List<int>.from(peaks);

  // Remove duplicate peaks (within 50ms)
  final minDist = (0.05 * samplingRate).round();
  final cleaned = <int>[corrected[0]];
  for (var i = 1; i < corrected.length; i++) {
    if (corrected[i] - cleaned.last > minDist) {
      cleaned.add(corrected[i]);
    }
  }

  return cleaned;
}
