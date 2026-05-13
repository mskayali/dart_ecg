/// ECG heartbeat segmentation.
///
/// Port of neurokit2.ecg_segment — extracts individual heartbeat
/// waveforms centered around R-peaks.
import 'dart:math' as math;

/// Segment ECG signal into individual heartbeats.
///
/// [ecgCleaned] — cleaned ECG signal.
/// [rpeaks] — R-peak indices.
/// [samplingRate] — sampling frequency in Hz.
/// [windowBefore] — seconds before R-peak to include.
/// [windowAfter] — seconds after R-peak to include.
///
/// Returns map of beat index → heartbeat waveform.
Map<int, List<double>> ecgSegment(
  List<double> ecgCleaned,
  List<int> rpeaks, {
  double samplingRate = 1000,
  double? windowBefore,
  double? windowAfter,
}) {
  if (rpeaks.isEmpty) return {};

  // Calculate mean RR interval
  final rrIntervals = <double>[];
  for (var i = 1; i < rpeaks.length; i++) {
    rrIntervals.add((rpeaks[i] - rpeaks[i - 1]).toDouble());
  }
  final meanRR = rrIntervals.isEmpty
      ? samplingRate
      : rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;

  // Default window: -0.35*RR to 0.65*RR
  final before = windowBefore != null
      ? (windowBefore * samplingRate).round()
      : (0.35 * meanRR).round();
  final after = windowAfter != null
      ? (windowAfter * samplingRate).round()
      : (0.65 * meanRR).round();

  final segments = <int, List<double>>{};

  for (var i = 0; i < rpeaks.length; i++) {
    final peak = rpeaks[i];
    final start = math.max(0, peak - before);
    final end = math.min(ecgCleaned.length, peak + after + 1);

    // Extract segment
    final segment = ecgCleaned.sublist(start, end);

    // Pad if necessary
    final targetLen = before + after + 1;
    if (segment.length < targetLen) {
      final padded = List<double>.filled(targetLen, 0.0);
      final offset = peak - before < 0 ? before - peak : 0;
      for (var j = 0; j < segment.length; j++) {
        padded[offset + j] = segment[j];
      }
      segments[i] = padded;
    } else {
      segments[i] = segment;
    }
  }

  return segments;
}
