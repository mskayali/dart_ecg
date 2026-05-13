/// Compute signal rate from peak indices.
///
/// Port of neurokit2.signal_rate.
import '../dsp/interpolate.dart';

/// Compute instantaneous rate from peak/event indices.
///
/// [peaks] — indices of detected events (e.g., R-peaks).
/// [samplingRate] — sampling frequency in Hz.
/// [desiredLength] — length of output (typically signal length).
///
/// Returns instantaneous rate in BPM at each sample point.
List<double> signalRate(
  List<int> peaks, {
  required double samplingRate,
  int? desiredLength,
}) {
  if (peaks.isEmpty) {
    return List<double>.filled(desiredLength ?? 0, 0.0);
  }
  if (peaks.length == 1) {
    return List<double>.filled(desiredLength ?? 1, 0.0);
  }

  // Calculate instantaneous rate at each peak
  final peakTimes = peaks.map((p) => p.toDouble()).toList();
  final rates = <double>[];

  for (var i = 0; i < peaks.length; i++) {
    if (i == 0) {
      // Use first interval for first peak
      final interval = (peaks[1] - peaks[0]) / samplingRate;
      rates.add(interval > 0 ? 60.0 / interval : 0.0);
    } else {
      final interval = (peaks[i] - peaks[i - 1]) / samplingRate;
      rates.add(interval > 0 ? 60.0 / interval : 0.0);
    }
  }

  // Interpolate to desired length
  final length = desiredLength ?? peaks.last + 1;
  final xNew = List<double>.generate(length, (i) => i.toDouble());

  return signalInterpolate(peakTimes, rates, xNew, method: 'linear');
}
