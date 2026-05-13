/// Signal fill missing values.
///
/// Port of neurokit2.signal_fillmissing.
/// Replaces NaN values in a signal using interpolation.
import '../dsp/interpolate.dart';

/// Fill missing (NaN) values in a signal.
///
/// [signal] — input signal (may contain NaN).
/// [method] — 'linear', 'nearest', 'previous'.
List<double> signalFillmissing(List<double> signal,
    {String method = 'linear'}) {
  final validIndices = <int>[];
  final validValues = <double>[];

  for (var i = 0; i < signal.length; i++) {
    if (!signal[i].isNaN) {
      validIndices.add(i);
      validValues.add(signal[i]);
    }
  }

  if (validIndices.isEmpty) return List<double>.filled(signal.length, 0.0);
  if (validIndices.length == signal.length) return List<double>.from(signal);

  final x = validIndices.map((i) => i.toDouble()).toList();
  final xNew = List<double>.generate(signal.length, (i) => i.toDouble());

  return signalInterpolate(x, validValues, xNew, method: method);
}
