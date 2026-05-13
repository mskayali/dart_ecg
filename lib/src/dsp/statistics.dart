/// Statistical functions for signal processing.
///
/// Provides kurtosis, rescale, standardize, and distance metrics
/// used by NeuroKit2's quality assessment and processing pipeline.
import 'dart:math' as math;

import 'array_ops.dart';

/// Compute kurtosis of a signal (Pearson's definition, fisher=False).
///
/// Pearson kurtosis = E[(X-μ)^4] / (E[(X-μ)^2])^2
/// This matches scipy.stats.kurtosis(x, fisher=False).
double kurtosis(List<double> signal, {bool fisher = false}) {
  final n = signal.length;
  if (n < 4) return 0.0;

  final m = signal.mean;
  var m2 = 0.0;
  var m4 = 0.0;

  for (final v in signal) {
    final d = v - m;
    final d2 = d * d;
    m2 += d2;
    m4 += d2 * d2;
  }

  m2 /= n;
  m4 /= n;

  if (m2 == 0) return 0.0;

  final k = m4 / (m2 * m2);
  return fisher ? k - 3.0 : k;
}

/// Rescale values to a target range [to[0], to[1]].
///
/// Equivalent to neurokit2.rescale.
List<double> rescale(List<double> signal,
    {List<double> to = const [0.0, 1.0]}) {
  if (signal.isEmpty) return [];

  final minVal = signal.min;
  final maxVal = signal.max;
  final range = maxVal - minVal;

  if (range == 0) return List<double>.filled(signal.length, to[0]);

  final targetRange = to[1] - to[0];
  return List<double>.generate(
    signal.length,
    (i) => ((signal[i] - minVal) / range) * targetRange + to[0],
  );
}

/// Standardize a signal (z-score normalization).
///
/// out = (x - mean) / std
List<double> standardize(List<double> signal) {
  final m = signal.mean;
  final s = signal.std;
  if (s == 0) return List<double>.filled(signal.length, 0.0);
  return List<double>.generate(signal.length, (i) => (signal[i] - m) / s);
}

/// Compute distance of each row from the mean row.
///
/// Used by ecg_quality averageQRS method.
/// [data] — 2D matrix as list of rows.
/// [method] — 'mean' for Euclidean distance from mean.
List<double> distance(List<List<double>> data, {String method = 'mean'}) {
  if (data.isEmpty) return [];

  final nRows = data.length;
  final nCols = data[0].length;

  // Compute mean row
  final meanRow = List<double>.filled(nCols, 0.0);
  for (var j = 0; j < nCols; j++) {
    for (var i = 0; i < nRows; i++) {
      meanRow[j] += data[i][j];
    }
    meanRow[j] /= nRows;
  }

  // Euclidean distance from mean
  final distances = List<double>.filled(nRows, 0.0);
  for (var i = 0; i < nRows; i++) {
    var d = 0.0;
    for (var j = 0; j < nCols; j++) {
      final diff = data[i][j] - meanRow[j];
      d += diff * diff;
    }
    distances[i] = math.sqrt(d);
  }

  return distances;
}

/// Correlation coefficient between two signals.
double correlation(List<double> a, List<double> b) {
  final n = math.min(a.length, b.length);
  if (n == 0) return 0.0;

  final ma = a.sublist(0, n).mean;
  final mb = b.sublist(0, n).mean;

  var num = 0.0;
  var denA = 0.0;
  var denB = 0.0;

  for (var i = 0; i < n; i++) {
    final da = a[i] - ma;
    final db = b[i] - mb;
    num += da * db;
    denA += da * da;
    denB += db * db;
  }

  final den = math.sqrt(denA * denB);
  if (den == 0) return 0.0;
  return num / den;
}

/// Normal (Gaussian) probability density function.
double normalPdf(double x, {double mean = 0.0, double std = 1.0}) {
  final z = (x - mean) / std;
  return math.exp(-0.5 * z * z) / (std * math.sqrt(2 * math.pi));
}
