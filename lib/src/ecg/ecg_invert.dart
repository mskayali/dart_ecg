/// ECG signal inversion detection and correction.
///
/// Port of neurokit2.ecg_invert — detects and corrects inverted ECG signals.
import '../dsp/array_ops.dart';

/// Detect and correct inverted ECG signals.
///
/// [ecgSignal] — ECG signal (raw or cleaned).
/// [samplingRate] — sampling frequency in Hz.
/// [forceInversion] — if true, always invert. If false, auto-detect.
///
/// Returns (signal, isInverted):
/// - signal: corrected signal.
/// - isInverted: whether inversion was applied.
({List<double> signal, bool isInverted}) ecgInvert(
  List<double> ecgSignal, {
  double samplingRate = 1000,
  bool? forceInversion,
}) {
  if (forceInversion == true) {
    return (signal: ecgSignal.scale(-1), isInverted: true);
  }
  if (forceInversion == false) {
    return (signal: List<double>.from(ecgSignal), isInverted: false);
  }

  // Auto-detect: compare positive vs negative peak areas
  // Using rolling window approach from NeuroKit2

  final n = ecgSignal.length;
  if (n == 0) return (signal: ecgSignal, isInverted: false);

  var posArea = 0.0;
  var negArea = 0.0;

  final m = ecgSignal.mean;

  for (var i = 0; i < n; i++) {
    final val = ecgSignal[i] - m;
    if (val > 0) {
      posArea += val;
    } else {
      negArea += val.abs();
    }
  }

  // If negative area significantly exceeds positive → signal is inverted
  final isInverted = negArea > posArea * 1.5;

  if (isInverted) {
    return (signal: ecgSignal.scale(-1), isInverted: true);
  }
  return (signal: List<double>.from(ecgSignal), isInverted: false);
}
