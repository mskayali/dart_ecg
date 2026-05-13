/// Peak detection utilities.
///
/// Port of scipy.signal.find_peaks and neurokit2.signal_zerocrossings.
import 'dart:math' as math;

import 'array_ops.dart';

/// Result of peak detection.
class PeakResult {
  /// Indices of detected peaks.
  final List<int> peaks;

  /// Peak heights (if requested).
  final List<double>? heights;

  /// Peak prominences (if requested).
  final List<double>? prominences;

  const PeakResult({
    required this.peaks,
    this.heights,
    this.prominences,
  });
}

/// Find peaks in a 1D signal.
///
/// Port of scipy.signal.find_peaks with key parameters:
/// - [height] — minimum peak height.
/// - [distance] — minimum distance between peaks (in samples).
/// - [prominence] — minimum prominence.
///
/// Returns [PeakResult] with indices and optional properties.
PeakResult findPeaks(
  List<double> signal, {
  double? height,
  int? distance,
  double? prominence,
}) {
  // Step 1: Find all local maxima
  var peaks = <int>[];
  for (var i = 1; i < signal.length - 1; i++) {
    if (signal[i] > signal[i - 1] && signal[i] >= signal[i + 1]) {
      peaks.add(i);
    }
  }

  // Step 2: Filter by height
  List<double>? heights;
  if (height != null) {
    final filtered = <int>[];
    final h = <double>[];
    for (final p in peaks) {
      if (signal[p] >= height) {
        filtered.add(p);
        h.add(signal[p]);
      }
    }
    peaks = filtered;
    heights = h;
  } else {
    heights = peaks.map((p) => signal[p]).toList();
  }

  // Step 3: Filter by distance (keep highest peak in each window)
  if (distance != null && distance > 0 && peaks.isNotEmpty) {
    // Sort peaks by height (descending) for priority
    final peaksByHeight = List<int>.from(peaks);
    peaksByHeight.sort((a, b) => signal[b].compareTo(signal[a]));

    final keep = List<bool>.filled(signal.length, false);
    final remove = List<bool>.filled(signal.length, false);
    final filteredPeaks = <int>[];

    for (final p in peaksByHeight) {
      if (!remove[p]) {
        filteredPeaks.add(p);
        keep[p] = true;
        // Mark neighbors for removal
        final left = math.max(0, p - distance);
        final right = math.min(signal.length - 1, p + distance);
        for (var j = left; j <= right; j++) {
          remove[j] = true;
        }
        remove[p] = false; // Don't remove the peak itself
      }
    }

    filteredPeaks.sort();
    peaks = filteredPeaks;
    heights = peaks.map((p) => signal[p]).toList();
  }

  // Step 4: Filter by prominence
  List<double>? prominences;
  if (prominence != null) {
    prominences = _calculateProminences(signal, peaks);
    final filtered = <int>[];
    final filteredProms = <double>[];
    final filteredHeights = <double>[];
    for (var i = 0; i < peaks.length; i++) {
      if (prominences[i] >= prominence) {
        filtered.add(peaks[i]);
        filteredProms.add(prominences[i]);
        filteredHeights.add(heights[i]);
      }
    }
    peaks = filtered;
    prominences = filteredProms;
    heights = filteredHeights;
  }

  return PeakResult(
    peaks: peaks,
    heights: heights,
    prominences: prominences,
  );
}

/// Calculate peak prominences.
/// Port of scipy.signal.peak_prominences.
List<double> _calculateProminences(List<double> signal, List<int> peaks) {
  final prominences = List<double>.filled(peaks.length, 0.0);

  for (var i = 0; i < peaks.length; i++) {
    final peak = peaks[i];
    final peakHeight = signal[peak];

    // Search left for the highest minimum
    var leftMin = peakHeight;
    for (var j = peak - 1; j >= 0; j--) {
      if (signal[j] > peakHeight) break;
      if (signal[j] < leftMin) leftMin = signal[j];
    }

    // Search right for the highest minimum
    var rightMin = peakHeight;
    for (var j = peak + 1; j < signal.length; j++) {
      if (signal[j] > peakHeight) break;
      if (signal[j] < rightMin) rightMin = signal[j];
    }

    prominences[i] = peakHeight - math.max(leftMin, rightMin);
  }

  return prominences;
}

/// Find zero crossings in a signal.
///
/// Returns indices where the signal changes sign.
/// Equivalent to neurokit2.signal_zerocrossings.
List<int> signalZerocrossings(List<double> signal,
    {String direction = 'both'}) {
  final crossings = <int>[];
  for (var i = 0; i < signal.length - 1; i++) {
    final cross = signal[i] * signal[i + 1];
    if (cross < 0) {
      if (direction == 'positive' && signal[i] < 0) {
        crossings.add(i);
      } else if (direction == 'negative' && signal[i] > 0) {
        crossings.add(i);
      } else if (direction == 'both') {
        crossings.add(i);
      }
    } else if (signal[i] == 0 && i > 0) {
      if (signal[i - 1] * signal[i + 1] < 0) {
        crossings.add(i);
      }
    }
  }
  return crossings;
}

/// Find peaks using simple threshold method.
///
/// Used internally by some NeuroKit2 peak detectors.
/// Detects all points above [threshold] that are local maxima.
List<int> peakDetect(List<double> signal, {double? threshold}) {
  final thresh = threshold ?? signal.mean;
  final peaks = <int>[];

  for (var i = 1; i < signal.length - 1; i++) {
    if (signal[i] > thresh &&
        signal[i] > signal[i - 1] &&
        signal[i] >= signal[i + 1]) {
      peaks.add(i);
    }
  }
  return peaks;
}

/// Moving Window Average.
///
/// Used by Elgendi, Pan-Tompkins and other ECG peak detectors.
List<double> movingWindowAverage(List<double> signal, int windowSize) {
  if (windowSize <= 0) return List<double>.from(signal);
  final n = signal.length;
  final result = List<double>.filled(n, 0.0);

  // Compute using running sum
  var windowSum = 0.0;
  for (var i = 0; i < math.min(windowSize, n); i++) {
    windowSum += signal[i];
  }

  for (var i = 0; i < n; i++) {
    final windowEnd = i;
    final windowStart = i - windowSize;

    if (windowEnd < windowSize) {
      // Still building the window
      if (i > 0) windowSum += signal[math.min(i, n - 1)];
      result[i] = windowSum / (i + 1);
    } else {
      windowSum += signal[windowEnd];
      windowSum -= signal[windowStart];
      result[i] = windowSum / windowSize;
    }
  }
  return result;
}
