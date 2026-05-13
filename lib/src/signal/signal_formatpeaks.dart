/// Format peak detection results as binary arrays.
///
/// Port of neurokit2.signal_formatpeaks.

/// Create a binary signal array marking peak positions.
///
/// [peakIndices] — list of peak sample indices.
/// [desiredLength] — length of output signal.
///
/// Returns a list of 0s with 1s at peak positions.
List<double> signalFormatpeaks(List<int> peakIndices, int desiredLength) {
  final result = List<double>.filled(desiredLength, 0.0);
  for (final idx in peakIndices) {
    if (idx >= 0 && idx < desiredLength) {
      result[idx] = 1.0;
    }
  }
  return result;
}
