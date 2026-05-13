/// Signal resampling utilities.
///
/// Port of scipy.signal.resample for changing sampling rates.

import 'interpolate.dart';

/// Resample a signal to a new length.
///
/// [signal] — input signal.
/// [targetLength] — desired number of samples.
/// [method] — 'linear' or 'cubic' interpolation.
///
/// Returns resampled signal.
List<double> signalResample(
  List<double> signal,
  int targetLength, {
  String method = 'linear',
}) {
  if (signal.isEmpty) return [];
  if (targetLength == signal.length) return List<double>.from(signal);

  final xOld = List<double>.generate(
      signal.length, (i) => i.toDouble() / (signal.length - 1));
  final xNew = List<double>.generate(
      targetLength, (i) => i.toDouble() / (targetLength - 1));

  return signalInterpolate(xOld, signal, xNew, method: method);
}

/// Resample signal from one sampling rate to another.
///
/// [signal] — input signal.
/// [originalRate] — original sampling rate in Hz.
/// [targetRate] — target sampling rate in Hz.
List<double> resampleByRate(
  List<double> signal, {
  required double originalRate,
  required double targetRate,
}) {
  final targetLength =
      (signal.length * targetRate / originalRate).round();
  return signalResample(signal, targetLength);
}
